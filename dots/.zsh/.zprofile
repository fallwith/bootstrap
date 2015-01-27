# keep everything private/personal in a separate file
if [[ -e "$HOME/.bootstrap_private" ]]; then source "$HOME/.bootstrap_private"; fi

export EDITOR=vi
export TERM=xterm-256color

PATH=$HOME/bin:$PATH

#   -l = long format
#   -A = include hidden (.*) files except '.' and '..'
#   -p = mark directories with a trailing slash ('/')
#   -G = colorized output
#   --color=always = for times when -G isn't sufficient
alias ll='ls -lApG --color=always'

# git
export GIT_SSL_NO_VERIFY=true

# homebrew
PATH=/usr/local/bin:/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/gnu-sed/libexec/gnubin:$PATH

# mysql
PATH=$PATH:/usr/local/mysql/bin
alias mysqlstop="sudo /Library/StartupItems/MySQLCOM/MySQLCOM stop"
alias mysqlstart="sudo /Library/StartupItems/MySQLCOM/MySQLCOM start"
alias mysqlrestart="sudo /Library/StartupItems/MySQLCOM/MySQLCOM restart"

# rvm
alias rvminstall="\curl -L https://get.rvm.io | bash -s stable --autolibs=enabled"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# mongo
alias mongostart="mongod --fork --config /usr/local/etc/mongod.conf"
alias mongostop="pkill mongod"
#To have launchd start mongodb at login:
#    ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents
#Then to load mongodb now:
#    launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist
#Or, if you don't want/need launchctl, you can just run:
#    mongod

# mysql
alias mysqlstart="mysql.server start"
alias mysqlstop="mysql.server stop"

# Clean up source code by converting tabs to 2 spaces, Windows newlines to
# unix ones, and by stripping away trailing whitespace. Pass in a list of
# files to clean, or let ag find a list of suitable candidates.
clean() {
  if [ $1 ]; then
    files=$@
  else
    files=`ag " +$|\t|\r" -l`
  fi
  echo $files|xargs perl -pi -e "s/\r\n?/\n/g;s/\t/ /g;s/[ ]*$//g"
}

# Switch between git users
gitidentity() {
  gitusername=$1
  gitemail=$2
  gitsshkey=$3
  if [[ ! "$gitusername" = "" && ! "$gitemail" = "" ]]; then
    git config --global user.name "$gitusername"
    git config --global user.email "$gitemail"
    if [[ ! "$gitsshkey" == "" && -e "$gitsshkey" ]]; then
      ssh-add -D
      ssh-add "$gitsshkey"
    fi
  else
    echo "Usage: gitidentify <user> <email> (/path/to/ssh/key)"
  fi
}

export JRUBY_OPTS='-Xcompile.invokedynamic=false -J-XX:+TieredCompilation -J-XX:TieredStopAtLevel=1 -J-noverify -Xcompile.mode=OFF -J-Xmx1024m --1.9'
export JAVA_HOME="$(/usr/libexec/java_home)"

# aws
export EC2_PRIVATE_KEY=~/.ec2/pk-amazon.pem
export EC2_CERT=~/.ec2/cert-amazon.pem
export AWS_CREDENTIAL_FILE=~/.ec2/.aws-credentials-master

# bundler
alias bspec='bundle exec rspec'
alias brake='noglob bundle exec rake'
