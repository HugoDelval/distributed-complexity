echo "push to dockerhub"
docker build --build-arg CACHEBUST=$(date +%s) .
docker images
echo "docker tag <tag> hugodelval/distributed-complexity"
echo "docker push hugodelval/distributed-complexity"
