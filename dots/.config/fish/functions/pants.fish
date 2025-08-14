function pants --description 'Run a Docker container with the current directory mounted'
  if test (count $argv) -eq 0
    echo "Usage: pants <image_name>"
    return 1
  end

  docker run --rm -it --mount "type=bind,source="(pwd)",target=/app" --name pants $argv[1] bash
end
