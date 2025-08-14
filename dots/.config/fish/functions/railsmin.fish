function railsmin --description 'Create a minimal Rails API application'
  if test (count $argv) -eq 0
    echo "Usage: railsmin <app_name>"
    return 1
  end

  bundle exec rails new $argv[1] --api --minimal --skip-git \
    --skip-action-mailer --skip-action-cable \
    --skip-javascript --skip-test --skip-keeps \
    --skip-asset-pipeline --skip-hotwire --skip-jbuilder \
    --skip-decrypted-diffs
end
