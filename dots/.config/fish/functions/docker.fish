function _docker_stop_all
    set -l containers (docker ps -aq)
    if test -n "$containers"
        docker container stop $containers
        docker container rm --force $containers
    end
end

function dockerclean --description 'Routine cleanup: containers, :latest images, unused volumes/cache'
    _docker_stop_all

    set -l images (docker images --filter 'reference=*:latest' --format '{{.ID}}')
    if test -n "$images"
        docker image rm $images
    end

    docker volume prune --all --force
    docker buildx prune --force
end

function dockerwipe --description 'Nuclear: stop containers, wipe all images/volumes/networks/build cache'
    _docker_stop_all
    docker system prune --all --volumes --force
    docker buildx prune --all --force
end
