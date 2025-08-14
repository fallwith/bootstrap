alias 15=fifteen
alias b='bundle exec'
alias cp='cp -i'
alias br='bundle exec rubocop (git status --porcelain | awk \'$2 ~ /\.rb$/ {print $2}\'| tr \'\n\' \' \' |sed \'s/ $//\')'
alias bra='bundle exec rubocop -a (git status --porcelain | awk \'$2 ~ /\.rb$/ {print $2}\'| tr \'\n\' \' \' |sed \'s/ $//\')'
alias brake='bundle exec rake'
alias brubo='bundle exec rubocop'
alias bspec='bundle exec rspec'
alias cdgem=gemcd
alias defaultgems='cat $HOME/.default-gems | grep -v "^#" | xargs -n 1 gem install'
alias dirs='fd -td'
alias dockerstop='docker ps -aq |xargs docker container stop'
alias dockerclean='docker ps -aq |xargs docker container stop; docker ps -aq |xargs docker container rm; docker images | grep latest | awk \'{print $3}\' | xargs docker image rm; docker volume prune --force; docker builder prune --force'
alias dockerwipe='docker images | awk \'{print $3}\' | xargs docker image rm --force; docker volume ls | tail -n+2 | awk \'{print $2}\'|xargs docker volume rm; dockerclean'
alias fd='fd --color never'
alias ghostty=/Applications/Ghostty.app/Contents/MacOS/ghostty
alias ghosttyconfig='nvim ~/.config/ghostty/config'
alias guide='nvim ~/git/public/vim_guide/vim_guide.md'
alias killrails="ps auwx | grep -E 'rails (master|worker)' | awk '{ print \$2 }' | xargs -I {} kill -9 {}"
alias ll='eza --long --all --group --numeric --classify --git --time-style long-iso'
alias lle='ll --extended'
alias mv='mv -i'
alias no="nvr -o"
alias plugins='nvim ~/.config/nvim/init.lua'
alias railsc='bundle exec bin/rails c'
alias railss='bundle exec bin/rails s'
alias running='ps auwx|grep -E "memcache|mongo|mysql|rabbit|redis|postgres|ruby|rails|puma|node|\.rb|gradle"|grep -v grep'
alias runningd='running; docker ps'
alias vi='nvim'
alias vim='nvim'
alias vimwiki="nvim ~/.vimwiki/index.md"
alias vw=vimwiki
alias wiki="nvim -c \"lua require('kiwi').open_wiki_index()\""
alias z='cd $HOME/(fd -td -d1 . ~ ~/.config ~/git | sed "s|$HOME/||g" | fzf +m --height 33% --border --layout=reverse)'

abbr -a brewtaps 'brew list --full-name | grep /'
abbr -a font 'kitty @ set-font-size'
abbr -a gpgtest 'echo testing | gpg --clearsign'
abbr -a gom "gometalinter --enable-all --line-length=120 --deadline=180s ./..."
abbr -a got 'go test -v ./...'
abbr -a matrix 'cxxmatrix -c \#FFC0CB -s rain-forever --frame-rate=40 --preserve-background --no-twinkle --no-diffuse'
abbr -a servicesstart 'brew services --all start'
abbr -a servicesstop 'brew services --all stop'
abbr -a uga 'ug --all'
abbr -a uge 'ug --perl-regexp'
abbr -a xattrdel 'xattr -c -r'
