function port --description 'Show which process is using a port'
  if test (count $argv) -eq 0
    echo "port() - determine which process is using a port"
    echo "Usage: port <port number>"
    return 1
  end

  lsof -i :$argv[1]
end
