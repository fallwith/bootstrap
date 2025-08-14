function upload --description 'Upload files to a remote host via rsync'
  if test (count $argv) -ne 3
    echo "Usage: upload <IP ADDRESS> <LOCAL PATH> <REMOTE PATH>"
    return 1
  end

  rsync --progress -avhLe ssh $argv[2] $argv[1]:$argv[3]
end
