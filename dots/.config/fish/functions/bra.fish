function bra --description 'Run rubocop -a on modified Ruby files'
  set -l files (git status --porcelain | awk '$2 ~ /\.rb$/ {print $2}')
  if test (count $files) -gt 0
    bundle exec rubocop -a $files
  else
    echo "No modified Ruby files found"
  end
end