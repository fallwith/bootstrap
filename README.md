bootstrap
=========

This repository includes my dotfiles and scripts for setting things up.


installation
------------
Clone the repository, place any private/personal values and overrides at
`~/.bootstrap_private`, and kick off the `init` script.

1. Clone the repository

  ```bash
  git clone https://github.com/fallwith/bootstrap.git && cd bootstrap
  ```

1. Create a `~/.bootstrap_private` file

  ```bash
  cp .bootstrap_private.template ~/.bootstrap_private
  vi ~/.bootstrap_private
  ```

1. Run the `init` script

  ```bash
  ./init
  ```

Then update the clone and re-run the `init` script periodically to pick
up changes.
