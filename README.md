bootstrap
=========

installation
------------
Clone the repository, place any private/personal values and overrides at ~/.bootstrap_private, and kick off the init script.

1. Clone the repository

```bash
git clone https://github.com/fallwith/bootstrap.git && cd bootstrap
```

2. Create a ~/.bootstrap_private file

```bash
cp .bootstrap_private.template ~/.bootstrap_private
vi ~/.bootstrap_private
```

3. Run the init script

```bash
./init
```

Then update the clone and re-run the init script periodically to pick up changes.


about
-----
bootstrap is software that allows the user to set up one or more machines - optionally from scratch - with helpful applications and configurations. 

Currently, the following operations are carried out:

1. [Homebrew][1] is used to install a series of helpful unix tools and libraries. See [dots/Brewfile](dots/Brewfile) for more details.

2. [Homebrew-cask][2] is used to install a series of OS X GUI applications such as Firefox, iTerm 2, etc. See [dots/Brewfile](dots/Brewfile) for more details.

3. Several OS X behavior configuration changes are made to cater to the power user's preferences. See [scripts/set_up_os_x](scripts/set_up_os_x) for more details.

4. [iTerm 2][4] - after being installed by Homebrew-cask - is configured with a custom property list file.

5. Several dot files for software such as The Silver Searcher, Pry, Git, Tmux, etc. are configured in the user's home directory.

6. [Vim][5] is configured and set up to use [Vundle][6] for plugin management.

6. [Zsh][7] is configured for a balance of power and speed by leveraging some of the work from both the [oh-my -zsh][8] and [Prezto][9] projects without loading either.

[1]: http://brew.sh/
[2]: https://github.com/phinze/homebrew-cask
[4]: http://www.iterm2.com/
[5]: http://www.vim.org/
[6]: https://github.com/gmarik/vundle
[7]: http://www.zsh.org/
[8]: https://github.com/robbyrussell/oh-my-zsh
[9]: https://github.com/sorin-ionescu/prezto



