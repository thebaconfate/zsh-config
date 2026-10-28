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
since 2026-09-20, cloned for older installs), `you-should-use` (always cloned; it names the
alias for a command you typed in full), and `fzf`, `zoxide` and `bat` (file previews
in fzf's Ctrl-T picker) through mise, or else dnf, apt, pacman or brew, checked in that order.
gcloud is not installed: its plugin only adds completion and stays silent without the SDK.
