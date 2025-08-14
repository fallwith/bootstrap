function fifteen --description 'Kill a process gracefully with escalating signals'
  set pid $argv[1]

  if test -z "$pid"
    echo "Usage: fifteen <pid>"
    return 1
  end

  for signal in 15 2 1 9
    set cmd "kill -$signal $pid"
    echo $cmd
    eval $cmd

    for i in (seq 20)
      if not pidrunning $pid
        echo "pid $pid no longer exists"
        return 0
      end
      sleep 0.1
    end
  end

  if pidrunning $pid
    echo "pid $pid still exists"
  end
end
