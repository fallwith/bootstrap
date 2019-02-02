bootstrap
=========

bootstrap is intended to help prep a new macOS based machine.

The following actions are performed:

* All files found in the `dots` subdirectory are symlinked
  beneath the user's home directory
* Desired macOS behavior settings (such as keyboard repeat rate)
  are configured
* Homebrew is installed and used to install CLI apps, casks,
  fonts, App Store apps, etc.
* A desired shell is installed by Homebrew and configured to
  be the user's default shell


### Prerequisites

Do these things before using bootstrap:

* Sign in to the App Store app with your iCloud account


### Usage

Clone the repo and run the included init script:

```shell
git clone https://github.com/fallwith/bootstrap.git
cd bootstrap
./init
```

Then periodically have one machine push a change to the
repo and the others update their clones and re-run `init`.


### Personalization

It is extremely unlikely that you'll want to set up
a macOS system in the exact same manner that I like to,
and bootstrap does not make much effort to accomodate
personalization.

My intention is that you will use bootstrap as a template
to borrow some ideas from or to fork entirely and make your
own. You are quite welcome to use it as you see fit.

I recommend that you use bootstrap for non-sensitive
content and that it remain publicly accessible via
Git so that the `git` which ships with macOS can be
used to clone bootstrap without authentication.

