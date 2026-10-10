typeset -U path

# Homebrew's environment (PATH, MANPATH, ...). ~/.zprofile sets it for login shells; it's
# repeated here so this file works on its own, because the plugin checks below look for
# Homebrew-installed tools. Skipped when the environment already has it (HOMEBREW_PREFIX
# is inherited from .zprofile or the parent shell), since `brew shellenv` costs ~30ms.
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [[ -x "$brew_bin" ]] && { eval "$("$brew_bin" shellenv)"; break; }
    done
    unset brew_bin
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Update oh-my-zsh quietly instead of asking [Y/n] in whichever new shell opens first
zstyle ':omz:update' mode auto

# Completion treats - and _ as the same character: my_f<Tab> also finds my-file
HYPHEN_INSENSITIVE="true"

# zsh-syntax-highlighting must be the last plugin.
# gcloud only adds tab completion, and stays silent on machines without the SDK.
plugins=(git z fzf gcloud zsh-autosuggestions zsh-syntax-highlighting)
# zoxide replaces the z plugin where it's installed (both define `z`; see the end of
# this file). Machines without zoxide keep the plugin.
(( $+commands[zoxide] )) && plugins=(${plugins:#z})
# fzf: Ctrl-R fuzzy history search, Ctrl-T file picker. Skipped where fzf isn't installed.
(( $+commands[fzf] )) || plugins=(${plugins:#fzf})

source $ZSH/oh-my-zsh.sh

# Tool environment variables
export ASDF_DIR="$HOME/.asdf"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# pnpm lives in a different place on macOS and Linux
if [[ -d "$HOME/Library/pnpm" ]]; then
    export PNPM_HOME="$HOME/Library/pnpm"
elif [[ -d "$HOME/.local/share/pnpm" ]]; then
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi

# Raspberry Pi Pico C/C++ SDK
[[ -d "$HOME/pico/pico-sdk" ]] && export PICO_SDK_PATH="$HOME/pico/pico-sdk"

# Railway CLI
[ -f "$HOME/.railway/env" ] && source "$HOME/.railway/env"

# Prepend directories to PATH, skipping any that don't exist on this machine.
# Later entries end up first, so they win when a command exists in several.
prepend_path() {
    for dir in "$@"; do
        [[ -d "$dir" ]] && path=("$dir" $path)
    done
}

school_paths=(
    "$HOME/Documents/Thesis/haai/executables/bin"   # thesis
    "$HOME/Documents/pharo-launcher"                # meta-programming and reflection
)

editor_paths=(
    "$HOME/Applications/idea/bin"                   # IntelliJ IDEA
    "/opt/nvim/bin"                                 # neovim
)

package_manager_paths=(
    "$HOME/.local/share/fnm"
    "$ASDF_DIR/bin"
    "$ASDF_DIR/shims"
    "$HOME/.local/bin"                              # pipx, mise
    "$HOME/.cargo/bin"
    ${PNPM_HOME:+"$PNPM_HOME/bin"}
)

prepend_path "${school_paths[@]}" "${editor_paths[@]}" "${package_manager_paths[@]}"

# Preferred editor: neovim if installed, vim otherwise
if (( $+commands[nvim] )); then
    export EDITOR="nvim"
else
    export EDITOR="vim"
fi

# Tool setup, only for tools installed on this machine
[[ -f "$ASDF_DIR/asdf.sh" ]] && . "$ASDF_DIR/asdf.sh"
(( $+commands[thefuck] )) && eval "$(thefuck --alias)"

# Version managers: prefer mise, fall back to fnm and pyenv where it isn't installed
if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
else
    (( $+commands[fnm] )) && eval "$(fnm env)"
    (( $+commands[pyenv] )) && eval "$(pyenv init -)"
fi

# zoxide, a smarter cd: `z foo` jumps to the most-used match, `zi` opens an fzf picker.
# Keep it last: it has to come after compinit (run by oh-my-zsh) for its completions.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
