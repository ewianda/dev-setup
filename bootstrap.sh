#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
GO_VERSION="${GO_VERSION:-1.23.2}"
NODE_VERSION="${NODE_VERSION:-lts}"
INSTALL_GO=true
INSTALL_NODE=true
INSTALL_VIM_PLUGINS=true
PACKAGE_MANAGER=""
PACKAGE_CACHE_UPDATED=false

usage() {
    cat <<'USAGE'
Bootstrap the development environment by installing required tooling and
symlinking dotfiles into the current user's home directory.

Usage: ./bootstrap.sh [options]

Options:
  --skip-go            Skip Go installation
  --skip-node          Skip Node.js (via nvm) installation
  --skip-vim-plugins   Skip Vim plugin installation
  -h, --help           Show this help message and exit
USAGE
}

log() {
    local level="$1"
    shift
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s [%s] %s\n' "$timestamp" "$level" "$*" >&2
}

log_info() {
    log "INFO" "$@"
}

log_warn() {
    log "WARN" "$@"
}

log_error() {
    log "ERROR" "$@"
}

trap 'log_error "Bootstrap failed at line $LINENO"' ERR

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

sudo_cmd() {
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

detect_package_manager() {
    if have_cmd apt-get; then
        PACKAGE_MANAGER="apt"
    elif have_cmd brew; then
        PACKAGE_MANAGER="brew"
    elif have_cmd dnf; then
        PACKAGE_MANAGER="dnf"
    elif have_cmd pacman; then
        PACKAGE_MANAGER="pacman"
    else
        log_warn "No supported package manager detected. Package installation will be skipped."
        PACKAGE_MANAGER="none"
    fi
}

update_package_cache() {
    if [ "$PACKAGE_MANAGER" = "apt" ] && [ "$PACKAGE_CACHE_UPDATED" = false ]; then
        log_info "Updating apt package cache"
        sudo_cmd apt-get update -yqq
        PACKAGE_CACHE_UPDATED=true
    fi
}

install_packages() {
    local packages=()
    case "$PACKAGE_MANAGER" in
        apt)
            for pkg in "$@"; do
                if dpkg -s "$pkg" >/dev/null 2>&1; then
                    continue
                fi
                packages+=("$pkg")
            done
            if [ ${#packages[@]} -gt 0 ]; then
                update_package_cache
                log_info "Installing packages via apt: ${packages[*]}"
                sudo_cmd apt-get install -yqq "${packages[@]}" --no-install-recommends
            fi
            ;;
        brew)
            for pkg in "$@"; do
                if brew list "$pkg" >/dev/null 2>&1; then
                    continue
                fi
                log_info "Installing $pkg via Homebrew"
                brew install "$pkg"
            done
            ;;
        dnf)
            for pkg in "$@"; do
                if rpm -q "$pkg" >/dev/null 2>&1; then
                    continue
                fi
                packages+=("$pkg")
            done
            if [ ${#packages[@]} -gt 0 ]; then
                log_info "Installing packages via dnf: ${packages[*]}"
                sudo_cmd dnf install -y "${packages[@]}"
            fi
            ;;
        pacman)
            for pkg in "$@"; do
                if pacman -Q "$pkg" >/dev/null 2>&1; then
                    continue
                fi
                packages+=("$pkg")
            done
            if [ ${#packages[@]} -gt 0 ]; then
                log_info "Installing packages via pacman: ${packages[*]}"
                sudo_cmd pacman -S --noconfirm "${packages[@]}"
            fi
            ;;
        none)
            log_warn "Skipping package installation because no supported package manager was detected"
            ;;
    esac
}

backup_existing_paths() {
    local package_dir="$1"
    local rel_path
    local target
    local backup
    local timestamp
    timestamp="${BACKUP_TIMESTAMP:-$(date '+%Y%m%d-%H%M%S')}"

    while IFS= read -r -d '' file; do
        rel_path="${file#"$package_dir/"}"
        target="$HOME/$rel_path"
        mkdir -p "$(dirname "$target")"
        if [ -L "$target" ] || [ ! -e "$target" ]; then
            continue
        fi
        backup="$target.backup-$timestamp"
        log_warn "Backing up existing file $target -> $backup"
        mv "$target" "$backup"
    done < <(find "$package_dir" -mindepth 1 \( -type f -o -type l \) -print0)
}

link_dotfiles() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        log_warn "Dotfiles directory $DOTFILES_DIR does not exist; skipping dotfile linking"
        return
    fi

    if ! have_cmd stow; then
        install_packages stow
    fi

    if ! have_cmd stow; then
        log_warn "stow command is not available; dotfiles will not be symlinked"
        return
    fi

    for package_dir in "$DOTFILES_DIR"/*; do
        [ -d "$package_dir" ] || continue
        backup_existing_paths "$package_dir"
        local package_name
        package_name="$(basename "$package_dir")"
        log_info "Symlinking dotfiles for package $package_name"
        stow --dir "$DOTFILES_DIR" --target "$HOME" --restow "$package_name"
    done
}

install_fzf() {
    if have_cmd fzf; then
        log_info "fzf is already installed"
        return
    fi

    case "$PACKAGE_MANAGER" in
        apt)
            install_packages fzf
            ;;
        brew)
            install_packages fzf
            "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish --no-zsh || true
            ;;
        dnf)
            install_packages fzf
            ;;
        pacman)
            install_packages fzf
            ;;
        none)
            log_warn "Could not install fzf automatically; please install it manually"
            ;;
    esac
}

install_golang() {
    if ! $INSTALL_GO; then
        return
    fi

    if have_cmd go; then
        log_info "Go is already installed"
        return
    fi

    local goroot
    goroot="${GOROOT:-$HOME/.local/share/go}"
    local tmp
    tmp="$(mktemp -d)"
    log_info "Installing Go ${GO_VERSION} to $goroot"
    mkdir -p "$goroot"
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o "$tmp/go.tar.gz"
    rm -rf "$goroot"/*
    tar -C "$goroot" --strip-components=1 -xzf "$tmp/go.tar.gz"
    rm -rf "$tmp"

    if [[ -x "$goroot/bin/go" ]]; then
        log_info "Installing Go tooling"
        "$goroot/bin/go" install github.com/bazelbuild/buildtools/buildifier@latest || log_warn "Failed to install buildifier"
    fi
}

install_node() {
    if ! $INSTALL_NODE; then
        return
    fi

    if have_cmd node; then
        log_info "Node.js is already installed"
        return
    fi

    local nvm_dir
    nvm_dir="${NVM_DIR:-$HOME/.nvm}"

    if [ ! -d "$nvm_dir" ]; then
        log_info "Installing nvm"
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi

    export NVM_DIR="$nvm_dir"
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    log_info "Installing Node.js (${NODE_VERSION}) via nvm"
    if [ "$NODE_VERSION" = "lts" ]; then
        nvm install --lts
        nvm alias default 'lts/*'
    else
        nvm install "$NODE_VERSION"
        nvm alias default "$NODE_VERSION"
    fi

    if have_cmd npm; then
        npm install --global yarn >/dev/null 2>&1 || log_warn "Failed to install yarn globally"
    fi
}

ensure_vim_dirs() {
    mkdir -p "$HOME/.config/vim"/autoload "$HOME/.config/vim"/backup "$HOME/.config/vim"/plugged "$HOME/.config/vim"/undo
}

install_vim_plugins() {
    if ! $INSTALL_VIM_PLUGINS; then
        return
    fi

    if ! have_cmd vim; then
        log_warn "Vim is not installed; skipping plugin installation"
        return
    fi

    if [ ! -f "$HOME/.config/vim/vimrc" ]; then
        log_warn "Vim configuration not found at ~/.config/vim/vimrc; skipping plugin installation"
        return
    fi

    local plug_path="$HOME/.config/vim/autoload/plug.vim"
    if [ ! -f "$plug_path" ]; then
        log_info "Installing vim-plug"
        curl -fsSL https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o "$plug_path"
    fi

    log_info "Installing and updating Vim plugins"
    vim +"PlugInstall --sync" +qall </dev/null || log_warn "PlugInstall failed"
    vim +"PlugUpdate" +qall </dev/null || log_warn "PlugUpdate failed"
    if command -v vim >/dev/null 2>&1; then
        vim +'CocInstall -sync coc-json coc-html coc-pyright coc-sh coc-go' +qall </dev/null || \
            log_warn "coc.nvim extensions failed to install"
    fi
}

install_shellcheck() {
    install_packages shellcheck
}

install_tmux() {
    install_packages tmux
}

install_vim() {
    case "$PACKAGE_MANAGER" in
        apt)
            install_packages vim-nox python3-dev python3-pip
            ;;
        brew)
            install_packages vim
            ;;
        dnf)
            install_packages vim-enhanced python3-devel python3-pip
            ;;
        pacman)
            install_packages vim python-pip
            ;;
        none)
            log_warn "Unable to install Vim automatically; please install it manually"
            ;;
    esac
}

install_base_packages() {
    case "$PACKAGE_MANAGER" in
        apt)
            install_packages git curl build-essential ca-certificates gnupg
            ;;
        brew)
            install_packages git curl ca-certificates
            ;;
        dnf)
            install_packages git curl @'Development Tools'
            ;;
        pacman)
            install_packages git curl base-devel
            ;;
    esac
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-go)
                INSTALL_GO=false
                shift
                ;;
            --skip-node)
                INSTALL_NODE=false
                shift
                ;;
            --skip-vim-plugins)
                INSTALL_VIM_PLUGINS=false
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    detect_package_manager
    install_base_packages
    install_vim
    install_tmux
    install_shellcheck
    install_fzf
    link_dotfiles
    ensure_vim_dirs
    install_vim_plugins
    install_golang
    install_node
    log_info "Bootstrap complete"
}

main "$@"
