function dockerwipe --description 'Nuclear: stop containers, wipe all images/volumes/networks/build cache'
    _docker_stop_all
    docker system prune --all --volumes --force
    docker buildx prune --all --force
end
