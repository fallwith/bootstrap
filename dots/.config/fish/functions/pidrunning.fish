function pidrunning --description 'Check if a process ID is running'
  ps -p $argv[1] >/dev/null 2>&1
end
