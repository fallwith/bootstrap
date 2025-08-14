function dockerclean --description 'Stop containers, remove them, remove latest images, and prune volumes/builder'
  docker ps -aq | xargs docker container stop
  docker ps -aq | xargs docker container rm
  docker images | grep latest | awk '{print $3}' | xargs docker image rm
  docker volume prune --force
  docker builder prune --force
end