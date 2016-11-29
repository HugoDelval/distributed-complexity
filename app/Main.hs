{-# LANGUAGE TemplateHaskell #-}
module Main where

import System.Environment (getArgs)
import System.Process
import System.Directory (doesDirectoryExist)
import Control.Distributed.Process
import Control.Distributed.Process.Node (initRemoteTable, runProcess)
import Control.Distributed.Process.Backend.SimpleLocalnet
import Control.Distributed.Process.Closure
import Control.Monad (forever, forM_)
import Data.List
import Data.List.Split
import Data.String.Utils
import Argon
import qualified Pipes.Prelude as P
import Pipes
import Pipes.Safe (runSafeT)
import System.IO.Silently


workerAnalyseComplexity :: (ProcessId, NodeId, String) -> Process ()
workerAnalyseComplexity (master, workerId, url) = do
  liftIO ( putStrLn $ "Starting worker : " ++ (show workerId) ++ " with parameter: " ++ url)
  let repoName = last $ splitOn "/" url
  gitRepoExists <- liftIO $ doesDirectoryExist ("/tmp/" ++ repoName)
  if not gitRepoExists then do
    liftIO $ callProcess "/usr/bin/git" ["clone", url, "/tmp/" ++ repoName]
  else do
    liftIO $ putStrLn "Repository already there."
  let conf = (Config 6 [] [] [] Colored)
  let source = allFiles ("/tmp/" ++ repoName)
              >-> P.mapM (liftIO . analyze conf)
              >-> P.map (filterResults conf)
              >-> P.filter filterNulls
  liftIO $ putStrLn $ "Launching analyse for " ++ url
  (output, _) <- liftIO $ capture $ runSafeT $ runEffect $ exportStream conf source
  -- liftIO $ callProcess "/bin/rm" ["-rf", "/tmp/" ++ repoName]
  liftIO ( putStrLn $ "End of worker : " ++ (show workerId) ++ " with parameter: " ++ url)
  send master $ (workerId, url, output)


remotable ['workerAnalyseComplexity]


myRemoteTable :: RemoteTable
myRemoteTable = Main.__remoteTable initRemoteTable

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["master", host, port] -> do
      backend <- initializeBackend host port myRemoteTable
      startMaster backend (master backend)
    ["slave", host, port] -> do
      backend <- initializeBackend host port myRemoteTable
      startSlave backend

master :: Backend -> [NodeId] -> Process ()
master backend slaves = do
  liftIO . putStrLn $ "Slaves: " ++ show slaves
  let repos = ["https://github.com/jepst/CloudHaskell", "https://github.com/mwotton/Hubris", "https://github.com/dmbarbour/Sirea", "https://github.com/michaelochurch/summer-2015-haskell-class", "https://github.com/jgoerzen/twidge", "https://github.com/ollef/Earley", "https://github.com/creswick/cabal-dev", "https://github.com/lambdacube3d/lambdacube-edsl"]
  responses <- feedSlavesAndGetResponses repos slaves [] []
  liftIO $ mapM (\(r,u) -> putStrLn $ "\n\n\n\n**************************************************************\n" ++ u ++ " :\n**************************************************************\n\n" ++  r) responses
  return ()
  -- terminateAllSlaves backend


feedSlavesAndGetResponses :: [String] -> [NodeId] -> [NodeId] -> [(String,String)] -> Process [(String,String)]
feedSlavesAndGetResponses [] freeSlaves [] responses = return responses
feedSlavesAndGetResponses repos freeSlaves busySlaves responses = do
  (restRepos, newBusySlaves, newFreeSlaves) <- feedSlaves repos freeSlaves []
  m <- expectTimeout 60000000 -- 1min max for each repo
  case m of
    Nothing            -> die "Master fatal failure, exiting."
    Just (slave, url, resp) -> feedSlavesAndGetResponses restRepos (slave:newFreeSlaves) (delete slave (newBusySlaves ++ busySlaves)) ((resp,url):responses)


feedSlaves :: [String] -> [NodeId] -> [NodeId] -> Process ([String], [NodeId], [NodeId])
feedSlaves [] slaves newBusySlaves = return ([], newBusySlaves, slaves)
feedSlaves repos [] newBusySlaves = return (repos, newBusySlaves, [])
feedSlaves (repo:repos) (oneSlave:slaves) newBusySlaves = do
  masterPid <- getSelfPid
  _ <- spawn oneSlave $ $(mkClosure 'workerAnalyseComplexity) (masterPid, oneSlave, repo :: String)
  feedSlaves repos slaves (oneSlave:newBusySlaves)

