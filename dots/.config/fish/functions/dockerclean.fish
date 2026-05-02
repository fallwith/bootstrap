function dockerclean --description 'Routine cleanup: containers, :latest images, unused volumes/cache'
    _docker_stop_all

    set -l images (docker images --filter 'reference=*:latest' --format '{{.ID}}')
    if test -n "$images"
        docker image rm $images
    end

    docker volume prune --all --force
    docker buildx prune --force
end
