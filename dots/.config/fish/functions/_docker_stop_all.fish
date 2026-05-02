function _docker_stop_all
    set -l containers (docker ps -aq)
    if test -n "$containers"
        docker container stop $containers
        docker container rm --force $containers
    end
end
