function dockerwipe --description 'Remove all docker images, volumes, and run dockerclean'
  docker images | awk '{print $3}' | xargs docker image rm --force
  docker volume ls | tail -n+2 | awk '{print $2}' | xargs docker volume rm
  dockerclean
end