typeset -U path

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# zsh-syntax-highlighting must be the last plugin
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)

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
