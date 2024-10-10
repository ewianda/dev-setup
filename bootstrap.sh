#!/usr/bin/env bash

set +eu

# Utility function to check if a command exists
have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Install Go
install_golang() {
    if have_cmd go; then
        echo "Go is already installed."
        return
    fi
    echo "Installing Go..."
    export GOROOT=$HOME/.go
    #curl -s https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash -s
    TEMP_DIRECTORY=$(mktemp -d)
    curl -o "$TEMP_DIRECTORY/go.tar.gz" https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
    tar -C "$GOROOT" --strip-components=1 -xzf "$TEMP_DIRECTORY/go.tar.gz"

    $GOROOT/bin/go install github.com/bazelbuild/buildtools/buildifier@latest
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

# Install fzf
install_fzf() {
    if have_cmd fzf; then
        echo "fzf is already installed."
        return
    fi
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
}

# Install Vim and configure
install_vim() {
    echo "Installing Vim..."
    sudo apt-get remove --purge -y vim vim-runtime gvim vim-gtk3 vim-common vim-gui-common
    sudo apt-get install -qqy vim-nox python3-dev python3-pip --no-install-recommends
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

# Backup function for files
backup() {
    local file
    for file in "$@"; do
        [[ -e "$file" ]] && mv -v "$file" "${file}-backup-$(date +%Y%m%d-%H%M)"
    done
}

# Install Vim configuration
install_vim_config() {
echo "Vim config"
    local vim_dir="$HOME/.config/vim"
    local vimrc="$vim_dir/vimrc"
    
    mkdir -p "$vim_dir/backup" "$vim_dir/plugged" "$vim_dir/undo" "$vim_dir/autoload"
    backup "$HOME/.vim"
    ln -sfn "$vim_dir" "$HOME/.vim"

    # Download vimrc and setup vim-plug
    #curl -fsSL "https://raw.githubusercontent.com/ewianda/dev-setup/main/.vimrc" -o "$vimrc"
    cp .vimrc "$vimrc"
    curl -fsSL https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o "$vim_dir/autoload/plug.vim"
    
    vim -c 'PlugInstall|qa'
    vim -c 'PlugUpdate|qa'
    vim +'CocInstall -sync coc-json coc-html coc-pyright coc-sh coc-go' +qall
echo "Done vim config"
}

# Install configuration files
install_config() {
    local gitconfig="$HOME/.config/git/config"
    
    mkdir -p "$HOME/.config/git"
    backup "$HOME/.gitconfig"
    
    # Use local .gitconfig (no curl required)
    cp gitconfig "$gitconfig"

    git config --global core.excludesFile '~/.gitignore'
echo "Done config"
}
# Configure bashrc
install_bashrc() {
    local bashrc="$HOME/.bashrc"
    
    backup "$bashrc"
    
    # Use local .bashrc
    cp bashrc "$bashrc"
    
    echo "Done bashrc configuration"
}


# Main function
main() {
    echo "Starting installation process..."
    sudo apt-get update -yqq
    sudo apt-get install -yqq default-jre shellcheck build-essential libncurses-dev tmux python3-dev curl
    install_bashrc
    install_git
    install_node
    install_fzf
    install_vim
    install_config
    install_vim_config
    install_golang
 
}

main "$@"
