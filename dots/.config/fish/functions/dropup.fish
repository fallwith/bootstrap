function dropup --description 'Upload files to Dropbox via rclone'
  if test (count $argv) -ne 2
    echo "Usage: dropup <local_path> <dropbox_path>"
    return 1
  end

  set src $argv[1]
  set dest $argv[2]

  rclone copy -P -vv --transfers 12 $src dropbox:$dest
end
