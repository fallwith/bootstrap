function dropdown --description 'Download files from Dropbox via rclone'
  if test (count $argv) -ne 2
    echo "Usage: dropdown <dropbox_path> <local_path>"
    return 1
  end

  set src $argv[1]
  set dest $argv[2]

  rclone copy -P -vv dropbox:$src $dest
end
