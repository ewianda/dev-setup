#!/usr/bin/env bash

set -euo pipefail

# Initialize BACKUP_DT variable to the current date and time if not already set
export BACKUP_DT=${BACKUP_DT:-$(date +%Y%m%d-%H%M)}

# Utility to check if a command exists
have_cmd() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            return 1
        fi
    done
    return 0
}

# Install Go
install_golang() {
    if have_cmd go; then
        echo "Go is already installed."
        return
    fi
    echo "Installing Go..."
    curl -s https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash -s -- --version 1.18
    "$GOROOT/bin/go" install github.com/bazelbuild/buildtools/buildifier@latest
}

# Install Git
install_git() {
    if have_cmd git; then
        echo "Git is already installed."
        return
    fi
    echo "Installing Git..."
    sudo apt-get install git -y
}

# Install Fzf
install_fzf() {
    if have_cmd fzf; then
        echo "Fzf is already installed."
        return
    fi
    echo "Installing Fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
}

# Install Vim
install_vim() {
    echo "Removing existing Vim installation (if present)..."
    sudo apt-get remove --purge -y vim vim-runtime gvim vim-tiny vim-common vim-gui-common

    echo "Installing Vim and related packages..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -qqy vim-nox python3-dev python3-pip --no-install-recommends

    echo "Setting Vim as the default editor..."
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 60
    sudo update-alternatives --skip-auto --config editor
}

# Install Node.js
install_node() {
    if have_cmd node; then
        echo "Node.js is already installed."
        return
    fi
    echo "Installing Node.js..."
    sudo curl -sL install-node.vercel.app/16 | sudo bash -s -- -y
    sudo npm install --global yarn
}

# Backup files
backup() {
    for file in "$@"; do
        if [[ -e "$file" ]]; then
            local backup_name="${file}-${BACKUP_DT}"
            echo "Backing up $file to $backup_name"
            mv -v "$file" "$backup_name" || { echo "Failed to backup $file"; return 1; }
        fi
    done
}

# Install Vim configuration
install_vim_config() {
    if [[ -L "$HOME/.vim" && -d "$HOME/.vim" && "$(readlink -f "$HOME/.vim")" == "$VIM" ]]; then
        echo "Vim config is already set up."
        return
    fi

    echo "Setting up Vim config..."
    mkdir -p "$VIM/backup" "$VIM/plugged" "$VIM/undo" "$VIM/autoload" "$VIM/tmp/bundle"
    backup "$HOME/.vim"
    ln -sfn "$VIM" "$HOME/.vim"

    update_vim_config
}

# Update Vim configuration using the local vimrc
update_vim_config() {
    echo "Updating Vim configuration..."
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
		declare -r VIM="$XDG_CONFIG_HOME"/vim
		declare -r VIMRC="$VIM"/vimrc
    backup "$VIMRC"

    # Use the vimrc from the same folder as the script
    cp "$(dirname "$0")/vimrc" "$VIMRC" || { echo "Failed to copy Vim configuration."; restore "$VIMRC"; }

    ln -sfn "$(basename "$VIM")" "$XDG_CONFIG_HOME/nvim"
    ln -sfn vimrc "$(dirname "$VIMRC")/init.vim"

    echo "Installing Vim plugins..."
    curl -fsSL --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o "$VIM/autoload/plug.vim"
    vim -c 'PlugInstall|qa'
    vim -c 'PlugUpdate|qa'
    vim +'CocInstall -sync coc-json coc-html coc-pyright coc-sh coc-go' +qall
}

# Install configuration files using local .gitconfig
install_config() {
    echo "Installing configuration files..."
    export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
    mkdir -p "$XDG_CONFIG_HOME/git"

    local gitconfig="$XDG_CONFIG_HOME/git/config"
    if [[ -e ~/.gitconfig || -e $gitconfig ]]; then
        backup ~/.gitconfig
    fi

    # Use the local .gitconfig file from the same directory
    cp "$(dirname "$0")/gitconfig" "$gitconfig"
}

# Main function
main() {
    echo "Starting installation process..."

    # Update and install base dependencies
    sudo apt update -yqq
    sudo apt install default-jre shellcheck build-essential libncurses-dev tmux python3-dev python3-pip -yqq

    # Call each function conditionally
    install_git
    install_node
    install_fzf
    install_vim
    install_config
    update_vim_config
    install_golang
}

# Execute main with arguments
main "$@"
