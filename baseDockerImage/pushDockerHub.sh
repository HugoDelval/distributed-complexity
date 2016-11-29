echo "push to dockerhub"
docker build .
docker images
echo "docker tag <tag> hugodelval/distributed-complexity"
echo "docker push hugodelval/distributed-complexity"
