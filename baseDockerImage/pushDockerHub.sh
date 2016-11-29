echo "push to dockerhub"
docker build --no-cache .
docker images
echo "docker tag <tag> hugodelval/distributed-complexity"
echo "docker push hugodelval/distributed-complexity"
