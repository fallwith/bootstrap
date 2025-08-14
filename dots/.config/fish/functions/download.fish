function download --description 'Download files from remote host via rsync'
  if test (count $argv) -ne 3
    echo "Usage: download <IP ADDRESS> <REMOTE PATH> <LOCAL PATH>"
    return 1
  end

  rsync --progress --rsync-path="sudo rsync" -avhLe ssh $argv[1]:$argv[2] $argv[3]
end
