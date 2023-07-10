#!/usr/bin/env bash
# go install mvdan.cc/sh/v3/cmd/shfmt@latest
# sudo apt install python3.10-venv
# yarn
# go install
# sudo apt install shellcheck

set +eu
have_cmd() {
  local p
  for p in "$@"; do
    command -v "$p" >/dev/null || return 1
  done
  return 0
}
install_golang() {
  if have_cmd go; then
    return 0
  fi
  echo >&2 "installing golang ..."
  export GOROOT=/usr/local/go
  export GOPATH=$HOME/go
  curl https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash -s -- --version 1.18
  $GOROOT/bin/go install github.com/bazelbuild/buildtools/buildifier@latest
}
install_git() {
  if have_cmd git; then
    return 0
  fi
  echo >&2 "installing git ..."
  sudo apt-get install git -y
}
install_fzf() {
  if have_cmd fzf; then
    return 0
  fi
  echo >&2 "installing fzf ..."
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all
}
install_vim() {
  if have_cmd vim; then
    install_vim_config
    return 0
  fi
  echo >&2 "installing vim ..."
  sudo apt-get install vim -yqq
  install_vim_config
}

install_node() {
  if have_cmd node; then
    return 0
  fi
  echo >&2 "installing node ..."
  sudo curl -sL install-node.vercel.app/16 | sudo bash -s -- -y
  sudo npm install --global yarn
}

export BACKUP_DT=${BACKUP_DT:-$(date +%Y%m%d-%H%M)}

backup_name() {
  echo "$1"-"$BACKUP_DT"
}

restore() {
  info "Restoring $1 ..."
  mv -v "$(backup_name "$1")" "$1"
}
backup() {
  local ii
  for ii in "$@"; do
    test -e "$ii" || continue
    if test -L "$ii"; then
      rm -v "$ii"
    else
      mv -v "$ii" "$(backup_name "$ii")" || die "Failed to backup $*"
    fi
  done
}

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -r VIM="$XDG_CONFIG_HOME"/vim
declare -r VIMRC="$VIM"/vimrc
VIMURL="https://raw.githubusercontent.com/ewianda/dev-setup/main/.vimrc"

install_vim_config() {

  # shellcheck disable=SC2235
  if test -L "$HOME"/.vim && test -d "$HOME/.vim"; then
    if [ "$(readlink -f "$HOME"/.vim)" = "$VIM" ]; then
      info "Vim home already exists"
    fi
  elif test -d "$HOME"/.vim && ! test -L "$HOME/.vim"; then
    if ! test -d "$VIM"; then
      mkdir -p "$(dirname $VIM)" && mv "$HOME/.vim" "$VIM" || die "Failed to move $HOME/.vim"
    fi
  fi

  backup "$HOME/.vim" || die "Failed to backup $HOME/.vim"

  if mkdir -p "$VIM"/{backup,plugged,undo,autoload,tmp/bundle}; then
    backup "$HOME/.vim"
    ln -sfn "$VIM" "$HOME/.vim"
  fi

  update_vim_config
}

update_vim_config() {
  backup "$VIMRC"
  if ! curl -fsSL "$VIMURL" -o "$VIMRC"; then
    restore "$VIMRC"
  fi

  backup "$XDG_CONFIG_HOME/nvim"
  ln -sfn "$(basename "$VIM")" "$XDG_CONFIG_HOME/nvim"
  ln -sfn vimrc "$(dirname "$VIMRC")"/init.vim
  if ! test -x "$HOME"/bin/diff-highlight; then
    curl -fsSL --create-dirs https://raw.githubusercontent.com/git/git/fd99e2bda0ca6a361ef03c04d6d7fdc7a9c40b78/contrib/diff-highlight/diff-highlight -o "$HOME"/bin/diff-highlight &&
      chmod +x "$HOME"/bin/diff-highlight
  fi

  curl -fsSL --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o $VIM/autoload/plug.vim
  vim -c 'PlugInstall|qa'
  vim -c 'PlugUpdate|qa'
  vim +'CocInstall -sync coc-json coc-html coc-pyright coc-sh coc-go' +qall

}

install_config() {
  export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
  mkdir -p $XDG_CONFIG_HOME/git
  GNAME="$(git config --global user.name)" || :
  GEMAIL="$(git config --global user.email)" || :
  GITCONF=$XDG_CONFIG_HOME/git/config
  if test -e ~/.gitconfig || test -e $GITCONF; then
    backup ~/.gitconfig
  fi
  curl -fsSL https://raw.githubusercontent.com/ewianda/dev-setup/Add-bootstrap/gitconfig -o ${GITCONF}
  [ -n "$GNAME" ] && git config --global user.name "$GNAME" || :
  [ -n "$GEMAIL" ] && git config --global user.email "$GEMAIL" || :
  git config --global core.excludesFile '~/.gitignore'

  # test -e ~/.tmux.conf || curl -fsSL https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/tmuxconf -o ~/.tmux.conf
  test -e ~/.inputrc || curl -fsSL https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/inputrc -o ~/.inputrc
  test -e ~/.bash_aliases || curl -fsSL https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/bash_aliases -o ~/.bash_aliases

  test -e ~/.gdbinit || curl -fsSL https://gist.githubusercontent.com/CocoaBeans/1879270/raw/c6972d5c32e38e9f35a3968c629b51973bd9d016/gdbinit -o ~/.gdbinit
}

main() {
  echo "Installing"
  (apt update -yqq && apt install sudo curl -yqq) || true
  sudo apt install default-jre shellcheck -yqq
  install_git
  install_node
  install_fzf
  install_vim
  install_config
  update_vim_config
  install_golang

}
main $@
