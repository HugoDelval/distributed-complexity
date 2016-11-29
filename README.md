# Distributed version of Argon (https://github.com/rubik/argon)
A distributed version of the Argon library, based on Cloud Haskell (haskell-distributed.github.io/)

Work started in the CS7051 class at Trinity.

## Installation

```bash
git clone https://github.com/HugoDelval/distributed-complexity
cd distributed-complexity
stack build
```

Note that you should have **UDP multicast** enabled and working in your environement, otherwise Cloud Haskell can't work.

## Run using stack

First create some clients

```bash
stack exec distributed-complexity-exe -- slave 0.0.0.0 1234
stack exec distributed-complexity-exe -- slave 0.0.0.0 1235
stack exec distributed-complexity-exe -- slave 0.0.0.0 1236
stack exec distributed-complexity-exe -- slave 0.0.0.0 1237
```

Then launch the maaster which will feed the slaves

```bash
stack exec distributed-complexity-exe -- master 0.0.0.0 1238
```

## Run using docker (tested on Open Nebula + docker-machine)

```bash
# For the slave(s) :
docker run -i -p 0.0.0.0:8001:8001 --net=host hugodelval/distributed-complexity stack exec distributed-complexity-exe slave 0.0.0.0 8001
# For the master
docker run -i -p 0.0.0.0:8002:8002 --net=host hugodelval/distributed-complexity stack exec distributed-complexity-exe master 0.0.0.0 8002
```

Note the use of ```--net=host``` option, which is needed to work easily with UDP multicast with docker. (cf https://hackage.haskell.org/package/distributed-process-simplelocalnet-0.2.3.3/docs/Control-Distributed-Process-Backend-SimpleLocalnet.html)

## Benchmark

Please see test/benchmark.pdf

Tested with a list of repositories :

```let repos = ["https://github.com/jepst/CloudHaskell",
		"https://github.com/mwotton/Hubris", 
		 "https://github.com/dmbarbour/Sirea", 
		 "https://github.com/michaelochurch/summer-2015-haskell-class", 
		 "https://github.com/jgoerzen/twidge", 
		 "https://github.com/ollef/Earley", 
		 "https://github.com/creswick/cabal-dev", 
		 "https://github.com/lambdacube3d/lambdacube-edsl"]```

