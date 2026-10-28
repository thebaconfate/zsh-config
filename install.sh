#!/usr/bin/env bash
# Installs what the plugin list in .zshrc needs but oh-my-zsh doesn't provide everywhere.
# Safe to re-run: anything already present is skipped. gcloud is left out on purpose: it's
# work-only, and its plugin stays silent on machines without the SDK.
#
#   ./install.sh            install what's missing
#   ./install.sh --dry-run  only show what would happen
set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

run() {
    if ((DRY_RUN)); then
        echo "    would run: $*"
    else
        "$@"
    fi
}

# link <file in this repo> <destination>: a real file already there is moved aside, never
# overwritten; an existing link to somewhere else is just re-pointed
link() {
    local src="$1" dest="$2"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        echo "$dest: already linked"
        return
    fi
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        echo "$dest: moving the existing file to $dest.bak"
        run mv "$dest" "$dest.bak"
    fi
    echo "$dest: linking to $src"
    run mkdir -p "$(dirname "$dest")"
    run ln -sfn "$src" "$dest"
}

# 1. oh-my-zsh. --keep-zshrc leaves the symlinked ~/.zshrc alone; --unattended stops the
#    installer from changing the login shell or starting zsh when it's done.
if [[ -d "$ZSH" ]]; then
    echo "oh-my-zsh: already installed"
elif ((DRY_RUN)); then
    echo "oh-my-zsh: would install with the official installer (--unattended --keep-zshrc)"
else
    echo "oh-my-zsh: installing"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended --keep-zshrc
fi

# 2. Community plugins, as <GitHub repo>:<plugin name>. oh-my-zsh bundles the zsh-users ones
#    since 2026-09-20, not you-should-use; what's missing is cloned into $ZSH_CUSTOM/plugins,
#    where oh-my-zsh looks first.
for plugin in zsh-users/zsh-autosuggestions:zsh-autosuggestions \
    zsh-users/zsh-syntax-highlighting:zsh-syntax-highlighting \
    MichaelAquilina/zsh-you-should-use:you-should-use; do
    repo="${plugin%%:*}" name="${plugin#*:}"
    if [[ -d "$ZSH/plugins/$name" || -d "$ZSH_CUSTOM/plugins/$name" ]]; then
        echo "$name: already available"
    else
        echo "$name: cloning into $ZSH_CUSTOM/plugins"
        run git clone --depth 1 "https://github.com/$repo.git" "$ZSH_CUSTOM/plugins/$name"
    fi
done

# 3. Programs the plugins rely on: fzf (fzf plugin), zoxide (replaces the z plugin) and bat
#    (previews in fzf's Ctrl-T picker).
#    Through mise where it's installed: mise/zsh.toml is linked in as an extra global config,
#    so every machine gets the same versions. The system package manager otherwise. .zshrc
#    runs `mise activate` before it picks its plugins, so it finds them either way.
install_tool() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        echo "$tool: already installed"
        return
    fi
    echo "$tool: installing"
    # dnf first (personal Fedora machines), and brew last so a Linux box that also has
    # Homebrew still uses the system package manager. On macOS only brew matches.
    if command -v dnf >/dev/null 2>&1; then
        run sudo dnf install -y "$tool"
    elif command -v apt-get >/dev/null 2>&1; then
        run sudo apt-get install -y "$tool"
    elif command -v pacman >/dev/null 2>&1; then
        run sudo pacman -S --needed --noconfirm "$tool"
    elif command -v brew >/dev/null 2>&1; then
        run brew install "$tool"
    else
        echo "    no supported package manager (dnf, apt, pacman, brew); install $tool by hand"
    fi
}
if command -v mise >/dev/null 2>&1; then
    link "$REPO/mise/zsh.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d/zsh.toml"
    echo "mise: installing fzf, zoxide and bat"
    run mise install
    # This script runs without `mise activate`; the shims put zoxide on PATH for step 4
    export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$PATH"
    hash -r
else
    install_tool fzf
    install_tool zoxide
    # Debian and Ubuntu install bat as batcat
    command -v batcat >/dev/null 2>&1 || install_tool bat
fi

# 4. Carry over the z plugin's history (~/.z) the first time zoxide is set up.
if [[ -f "$HOME/.z" ]] && command -v zoxide >/dev/null 2>&1 && [[ -z "$(zoxide query --list 2>/dev/null)" ]]; then
    echo "zoxide: importing $(wc -l <"$HOME/.z" | tr -d ' ') directories from ~/.z"
    # zoxide 0.10 reads ~/.z itself; older versions take the path explicitly.
    run zoxide import z 2>/dev/null || run zoxide import --from z "$HOME/.z"
fi

echo
echo "Done. Start a new shell (or run: exec zsh) to pick everything up."
