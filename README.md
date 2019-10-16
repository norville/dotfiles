# Bassa's Dotfiles

## Why

To quickly restore my computer environment: apps, tools, frameworks and preferences.

## How

With lots of cool ideas taken from [Github does dotfiles](https://dotfiles.github.io/)

## TODO
Clean install without xcode-select
Check ZSH path
Add mackup.cfg

## Install

Optional
```bash
xcode-select --install
sudo xcode-select -switch /Applications/Xcode.app
```

Before install sign in to Mac App Store

Then
```bash
wget -O - https://raw.githubusercontent.com/norville/dotfiles/bare/bin/dfboot | bash
```
Or
```bash
curl -L https://raw.githubusercontent.com/norville/dotfiles/bare/bin/dfboot | bash
```
