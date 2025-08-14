function br --description 'Run rubocop on modified Ruby files'
  set -l files (git status --porcelain | awk '$2 ~ /\.rb$/ {print $2}')
  if test (count $files) -gt 0
    bundle exec rubocop $files
  else
    echo "No modified Ruby files found"
  end
end