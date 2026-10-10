# zsh-config
Just my zsh config

## Setup

```sh
ln -s ~/.dotfiles/zsh-config/.zshrc ~/.zshrc
./install.sh --dry-run   # see what's missing on this machine
./install.sh             # install it
```

`install.sh` installs what the plugin list needs and skips anything already present:
oh-my-zsh, `zsh-autosuggestions` and `zsh-syntax-highlighting` (bundled with oh-my-zsh
since 2026-09-20, cloned for older installs), and `fzf` and `zoxide` through dnf, apt,
pacman or brew, checked in that order. gcloud is not installed: its plugin only adds
completion and stays silent without the SDK.
