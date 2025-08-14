function rcopy --description 'Sync files with rclone'
  if test (count $argv) -ne 2
    echo "Usage: rcopy <source> <destination>"
    return 1
  end

  rclone sync --progress --transfers 8 --size-only $argv[1] $argv[2]
end
