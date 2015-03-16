function git_branch(){
  [ -e $PWD/.git ] || return
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "$GIT_BRANCH_PREFIX${ref#refs/heads/}$GIT_BRANCH_SUFFIX"
}
