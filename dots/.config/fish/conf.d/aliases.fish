alias 15=fifteen
alias b='bundle exec'
alias cp='cp -i'
alias brake='bundle exec rake'
alias brubo='bundle exec rubocop'
alias bspec='bundle exec rspec'
alias cdgem=gemcd
alias defaultgems='cat $HOME/.default-gems | grep -v "^#" | xargs -n 1 gem install'
alias dirs='fd -td'
alias dockerstop='docker ps -aq |xargs docker container stop'
alias fd='fd --color never'
alias ghostty=/Applications/Ghostty.app/Contents/MacOS/ghostty
alias ghosttyconfig='nvim ~/.config/ghostty/config'
alias guide='nvim ~/git/public/vim_guide/vim_guide.md'
alias ll='eza --long --all --group --numeric --classify --git --time-style long-iso'
alias lle='ll --extended'
alias mv='mv -i'
alias no="nvr -o"
alias plugins='nvim ~/.config/nvim/init.lua'
alias railsc='bundle exec bin/rails c'
alias railss='bundle exec bin/rails s'
alias running='ps auwx|grep -E "memcache|mongo|mysql|rabbit|redis|postgres|ruby|rails|puma|node|\.rb|gradle"|grep -v grep'
alias vi='nvim'
alias vim='nvim'
alias vimwiki="nvim ~/.vimwiki/index.md"
alias vw=vimwiki
alias wiki="nvim -c \"lua require('kiwi').open_wiki_index()\""

abbr -a ayu "fish_config theme save 'ayu Mirage'"
abbr -a brewtaps 'brew list --full-name | grep /'
abbr -a config 'cd ~/.config/fish'
abbr -a font 'kitty @ set-font-size'
abbr -a gpgtest 'echo testing | gpg --clearsign'
abbr -a gom "gometalinter --enable-all --line-length=120 --deadline=180s ./..."
abbr -a got 'go test -v ./...'
abbr -a matrix 'cxxmatrix -c \#FFC0CB -s rain-forever --frame-rate=40 --preserve-background --no-twinkle --no-diffuse'
abbr -a servicesstart 'brew services --all start'
abbr -a servicesstop 'brew services --all stop'
abbr -a uga 'ug --all'
abbr -a uge 'ug --perl-regexp'
abbr -a which 'fishwhich'
abbr -a xattrdel 'xattr -c -r'
