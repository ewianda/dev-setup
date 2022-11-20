#!/usr/bin/env bash
#
# install: curl -fsSL https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/bootstrap.sh | bash -e
# fork: https://gist.github.com/ambakshi/51c994271a216016edef
# short url: curl -fsSL http://bit.ly/devbootstrap | bash -e
#
# ChangeLog:
#   09/26/2020  - Modularize script
#   12`1/21/2016  - Add Arch support
#   05/19/2017  - Add .gdbinit
#   05/28/2018  - Add amazon linux support
#   01/09/2021  - Moved config files to $XDG_CONFIG_HOME
# Amit Bakshi
#
# shellcheck disable=SC2086,SC2046,SC1091,SC21153,SC2015,SC2207,2155
_osid() {
    unset ELVERSION UBVERSION VERSTRING VERSION_ID ID PRETTY_NAME VERSION
    if [[ $OSTYPE =~ darwin ]]; then
        VERSTRING="$OSTYPE"
    elif [[ $OSTYPE =~ freebsd ]]; then
        VERSTRING="$OSTYPE"
    elif [ -f /etc/os-release ]; then

        . /etc/os-release
        case "$ID" in
            antergos)
                VERSTRING="arch"
                ;;
            rhel | ol | centos)
                ELVERSION="$(echo $VERSION_ID | cut -d'.' -f1)"
                ;;
            ubuntu)
                UBVERSION="$(echo $VERSION_ID | cut -d'.' -f1)"
                VERSTRING="ub${UBVERSION}"
                ;;
            amzn)
                if [[ $CPE_NAME =~ ^cpe:/o:amazon:linux:20 ]]; then
                    ELVERSION=6
                    VERSTRING=amzn1
                else
                    ELVERSION=7
                    VERSTRING=amzn2
                fi
                ;;
            *)
                # shellcheck disable=SC2153
                echo >&2 "Unknown OS version: $PRETTY_NAME ($VERSION)"
                ;;
        esac
    fi

    if [ -z "$VERSTRING" ] && [ -e /etc/system-release ]; then
        RELEASE="$(rpm -q $(rpm -qf /etc/system-release) --queryformat '%{VERSION}')"
        case "$RELEASE" in
            6Server) VERSTRING="rhel6" ;;
            7Server) VERSTRING="rhel7" ;;
            8Server) VERSTRING="rhel8" ;;
            6) VERSTRING="el6" ;;
            7) VERSTRING="el7" ;;
            8) VERSTRING="el8" ;;
            *)
                echo >&2 "Unknown version of EL: $RELEASE"
                echo >&2 "Please set VERSTRING to rhel6, el6, rhel7 or el7 manually before running this script"
                exit 1
                ;;
        esac
        ELVERSION="${RELEASE:0:1}"
        VERSTRING="${VERSTRING:-el${ELVERSION}}"
    fi

    if [ -z "$VERSTRING" ]; then
        cat >&2 /etc/*-release
        echo >&2 "Unknown OS version"
        uname -a >&2
        exit 1
    fi
    [ $# -eq 0 ] && set -- -f
    for cmd in "$@"; do
        case "$cmd" in
            -f | --full) echo "$VERSTRING" ;;
            -s | --split) echo "$VERSTRING" | sed -E -e 's/([a-z]+)([0-9\.]+)/\1 \2/g' ;;
            -p | --package)
                case "$VERSTRING" in
                    ub*) echo "deb" ;;
                    amzn* | el* | rhel*) echo "rpm" ;;
                esac
                ;;
            -*)
                echo >&2 "Unknown option $cmd"
                exit 1
                ;;
        esac
    done
}

have_pkg() {
    local pkg=
    if [[ $OSID_NAME =~ ^ub ]]; then
        for pkg in "$@"; do
            dpkg -l $pkg &>/dev/null || return 1
        done
        return 0
    elif [[ $OSID_NAME =~ el(6|7)$ ]] || [[ $OSID_NAME =~ ^amzn ]]; then
        for pkg in "$@"; do
            rpm -q $pkg &>/dev/null || return 1
        done
        return 0
    fi
    return 1
}
have_cmd () {
    local p
    for p in "$@"; do
        command -v "$p" >/dev/null || return 1
    done
    return 0
}

info() {
    echo >&2 "info: $1"
}

die() {
    echo >&2 "ERROR: $1"
    exit 1
}

install_pkg() {
    if [ "${ELVERSION:-0}" -gt 7 ]; then
        $SUDO dnf install -q -y "$@"
    elif [[ $OSID_NAME =~ ^ub ]]; then
        $SUDO apt-get update -yqq
        $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends "$@"
    elif [[ $OSID_NAME =~ ^el ]] || [[ $OSID_NAME =~ ^amzn ]]; then
        $SUDO yum install -y -q "$@"
    elif [[ $OSID_NAME =~ ^freebsd ]]; then
        $SUDO pkg install -y "$@"
    elif [[ $OSID_NAME =~ ^darwin ]]; then
        local pkg=
        for pkg in "$@"; do
            brew install $pkg
        done
    elif [[ $OSID_NAME =~ arch ]]; then
        $SUDO pacman -S --noconfirm "$@"
    else
        echo >&2 "Don't know how to install $* on $OSID_NAME"
        return 1
    fi
}

install_pkgs() {
    local ii
    local pkgs=()
    for ii in "$@"; do
        have_pkg "$ii" || pkgs+=("$ii")
    done
    if [ ${#pkgs[*]} -gt 0 ]; then
        install_pkg "${pkgs[@]}"
    fi
}

install_setup() {
    local pkgs=()

    if [[ $OSID_NAME =~ ^darwin ]]; then
        command -v brew >/dev/null || $SUDO -H ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1
        brew update
    elif [[ $OSID_NAME =~ ^freebsd ]]; then
        pkg install -y git tmux curl
    elif [[ $OSID_NAME =~ ^ub ]]; then
        if ! have_cmd git curl unzip; then
            echo >&2 "installing setup requirements ..."        
            install_pkgs curl software-properties-common git curl unzip
        fi
    elif [[ $OSID_NAME =~ ^el ]] || [[ $OSID_NAME =~ ^amzn ]]; then
        install_pkgs sudo curl git tar gzip
        [ $OSID_NAME = amzn2 ] && $SUDO amazon-linux-extras install -y epel || install_pkg epel-release unzip curl git
    elif [[ $OSID_NAME =~ rhel ]]; then
        $SUDO yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${ELVERSION}.noarch.rpm curl git unzip
    elif [[ $OSID_NAME =~ arch ]]; then
        $SUDO pacman -S --noconfirm git curl
    elif test -e /etc/system-release; then
        $SUDO yum -y install epel-release curl git tar gzip unzip curl
    fi
}

setup_nvim() {
    $SUDO update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
    $SUDO update-alternatives --skip-auto --config vi
    $SUDO update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
    $SUDO update-alternatives --skip-auto --config vim
    $SUDO update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
    $SUDO update-alternatives --skip-auto --config editor
    $SUDO -H pip install -U neovim || true
    $SUDO -H pip2 install -U neovim || true
    $SUDO -H pip3 install -U neovim || true
}

install_vim() {
    if have_cmd vim; then
        return 0
    fi
    echo >&2 "installing vim ..."
    if [[ $OSID_NAME =~ ^darwin ]]; then
        install_pkg neovim/neovim/neovim
    elif [[ $OSID_NAME =~ ^freebsd ]]; then
        pkg install -y neovim
    elif [[ $OSID_NAME =~ ^ub ]]; then
        if [[ $OSID_VERSION -lt 18 ]]; then
            $SUDO add-apt-repository -y ppa:neovim-ppa/stable
            $SUDO apt-get update -qq
            $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -qqy neovim python-dev python-pip python3-dev python3-pip --no-install-recommends
            setup_nvim
        else
            $SUDO apt-get update -qq
            $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -qqy vim-nox python3-dev python3-pip --no-install-recommends
            $SUDO update-alternatives --install /usr/bin/editor editor /usr/bin/vim 60
            $SUDO update-alternatives --skip-auto --config editor
        fi
    elif [[ $OSID_NAME =~ arch ]]; then
        pacman -S --noconfirm tmux neovim
    elif [[ $OSID_NAME =~ ^el ]] && [[ $OSID_VERSION -ge 7 ]]; then
        $SUDO yum localinstall -y https://storage.googleapis.com/repo.xcalar.net/xcalar-release-${OSID}.rpm || true
        #sudo curl -o /etc/yum.repos.d/dperson-neovim-epel-7.repo https://copr.fedorainfracloud.org/coprs/dperson/neovim/repo/epel-7/dperson-neovim-epel-7.repo
        $SUDO yum -y --enablerepo='xcalar*' install neovim universal-ctags shellcheck shfmt ripgrep patchelf restic || true
        setup_nvim
    elif [[ $OSID =~ amzn2 ]]; then
        $SUDO amazon-linux-extras install -y vim ruby2.6
    else
        echo >&2 "Don't know how to install neovim on ${OSID_NAME}${OSID_VERSION}"
        return 1
    fi
}

install_golang_tools() {
    export GOPATH=${GOPATH:-$HOME/go}
    local tmp=$(mktemp -d -t gitXXXXXX)
    mkdir -p $HOME/bin/
    (
    set -e
    git clone --branch v2.8.2 https://github.com/hashicorp/hcl $tmp/hcl
    cd $tmp/hcl/cmd/hclfmt
    go build -o ~/bin/hclfmt
    )
    rm -rf $tmp
    go get github.com/direnv/direnv
    for pkg in "$GOPATH"/bin/*; do
        if ((IS_ROOT)); then
            $SUDO ln -sfn ${pkg} /usr/local/bin/
        fi        
        ln -sfn ${pkg} $HOME/bin/
    done
}

install_golang() {
    BASEURL=https://golang.org

    if [ -z "$1" ]; then
        echo >&2 "${FUNC_NAME[0]}: Must specify destination dir"
        return 1
    fi

    if ! GOURL=$(curl -fsSL $BASEURL/dl | grep -Eow 'dl/go1\.([0-9\.]+)linux-amd64.tar.gz' | head -1); then
        return 1
    fi
    local version
    version="1.$(echo $GOURL | grep -Eow '([0-9\.]+)')"
    if ! test -x "$1"/go${version}/bin/go; then
        mkdir -p "$1"/go${version} || return 1
        curl -fL "${BASEURL}/${GOURL}" | $SUDO tar zxf - -C "$1"/go${version} --strip-components=1
    fi
    $SUDO ln -sfn go${version} "$1"/go
    test -e "$1"/bin || $SUDO mkdir -p "$1"/bin
    for cmd in go gofmt; do
        $SUDO ln -sfn ../go/bin/${cmd} "$1"/bin/${cmd}
    done
}

install_extras() {
    if test -e /etc/system-release; then
        $SUDO yum localinstall -y https://storage.googleapis.com/repo.xcalar.net/xcalar-release-${OSID}.rpm || true
        $SUDO yum -y --enablerepo='xcalar*' install tmux universal-ctags shellcheck shfmt ripgrep patchelf restic direnv shellcheck || true
    fi
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
VIMURL="https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/vimrc"

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

    if ! command -v ctags &>/dev/null; then
        sed -i.bak "s#^Plug 'vim-scripts/taglist.vim'#\" Plug 'vim-scripts/taglist.vim'#g" $VIMRC
        info "No ctags found. Commenting out taglist.vim plugin from ~/.vimrc"
    fi
    curl -fsSL --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o $VIM/autoload/plug.vim
    if ! test -x "$HOME"/bin/diff-highlight; then
        curl -fsSL --create-dirs https://raw.githubusercontent.com/git/git/fd99e2bda0ca6a361ef03c04d6d7fdc7a9c40b78/contrib/diff-highlight/diff-highlight -o "$HOME"/bin/diff-highlight \
        && chmod +x "$HOME"/bin/diff-highlight
    fi

    ## Get rid of YouCompleteMe plugin if you can't build it.
    #if ! which cmake &>/dev/null; then
    #  sed -i.bak "s#^Plugin 'Valloric/YouCompleteMe'#\" Plugin 'Valloric/YouCompleteMe'#g" ~/.vimrc
    #  echo >&2 "No cmake found. Commenting out YouCompleteMe plugin form ~/.vimrc"
    #fi

    if [ -r /dev/tty ]; then
      bash -c '</dev/tty vim "$@"' vim -T dumb '+PlugInstall' '+PlugUpgrade' '+qall!' || true
    elif ! [[ $OSTYPE =~ ^freebsd ]]; then
        if command -v nvim &>/dev/null; then
            nvim --headless -c ':PlugUpgrade' -c ':PlugUpdate' -c ':qall' || true
        elif command -v vim &>/dev/null; then
            vim -T dumb -c ':PlugUpgrade' -c ':PlugUpdate' -c ':qall' || true
        fi
    fi
    #fi
    #(cd ~/.vim/bundle/vim-airline/autoload/airline/themes && wget https://raw.githubusercontent.com/vim-airline/vim-airline-themes/master/autoload/airline/themes/powerlineish.vim)

    ##[ -e ~/.vim/bundle/YouCompleteMe ] && cd ~/.vim/bundle/YouCompleteMe && git submodule update --init && ./install.sh || true
}



install_arkade() {
    $SUDO curl -fsSL https://github.com/alexellis/arkade/releases/download/0.6.23/arkade --o /usr/local/bin/arkade
    $SUDO chmod +x /usr/local/bin/arkade
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
    curl -fsSL https://gist.github.com/ambakshi/d111202b21041db55a80/raw -o ${GITCONF}
    [ -n "$GNAME" ] && git config --global user.name "$GNAME" || :
    [ -n "$GEMAIL" ] && git config --global user.email "$GEMAIL" || :

    test -e ~/.tmux.conf || curl -fsSL https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/tmuxconf -o ~/.tmux.conf
    test -e ~/.inputrc || curl -fsSL https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/inputrc -o ~/.inputrc
    test -e ~/.bash_aliases || curl -fsSL https://gist.githubusercontent.com/ambakshi/51c994271a216016edef/raw/bash_aliases -o ~/.bash_aliases

    test -e ~/.gdbinit || curl -fsSL https://gist.githubusercontent.com/CocoaBeans/1879270/raw/c6972d5c32e38e9f35a3968c629b51973bd9d016/gdbinit -o ~/.gdbinit
}

usage() {
    echo "usage: $0 [--[no-]config] [--[no-]vim] [--[no-]vim-config] [--[no-]golang ] [--[no-]extras] [--[no-]golang-tools] [--hashitool[=x.y.z]]"
    echo
}

hashilatest () {
    local version;
    if version="$(curl -fsSL https://releases.hashicorp.com/$1/ | grep -Eow "${1}_[0-9\.]+" | sort -rV | head -1)"; then
        echo "${version#${1}_}";
        return 0;
    fi;
    return 1
}

hashiurl ()
{
    local tool="$1" version="$2";
    shift 2;
    if [ -z "$version" ] || [ "$version" = latest ]; then
        if ! version="$(hashilatest $tool)"; then
            return 1;
        fi;
    fi;
    local target
    target="$(uname -s)";
    target="${target,,}";
    local arch="amd64";
    case "$(uname -m)" in
        x86_64)
            arch=amd64
        ;;
        *)
            echo "Unknown architecture: $(uname -m)" 1>&2;
            return 1
        ;;
    esac;
    echo "https://releases.hashicorp.com/${tool}/${version}/${tool}_${version}_${target}_${arch}.zip"
}


download_hashitool ()
{
    local tool="$1";
    local version="$2";
    echo >&2 " -- download_hashitool $*"
    if test -e "$tool"; then
        echo "$tool already exists" 1>&2;
        return 1;
    fi;
    local target
    target="$(uname -s | tr '[:upper:]' '[:lower:]')";
    local arch="amd64";
    case "$(uname -m)" in
        x86_64)
            arch=amd64
        ;;
        *)
            echo "Unknown architecture: $(uname -m)" 1>&2;
            return 1
        ;;
    esac;
    local url
    if ! url="$(hashiurl $tool $version)"; then
        return 1
    fi
    if ! curl -fsSL "$url" -o ${tool}-$$.zip > /dev/null 2>&1; then
        return 1
    fi
    local  pzip="unzip"
    if have_cmd unzip; then
        pzip="unzip -o -q"
    elif have_cmd 7z; then
        pzip="7z x"
    else
        echo >&2 "unzip not found, leaving ${tool}.zip"
        mv ${tool}-$$.zip ${tool}.zip
        return
    fi

    $pzip ${tool}-$$.zip 1>&2 && rm -vf ${tool}-$$.zip || return 1
    if ((IS_ROOT)); then
        $SUDO mv "$tool" /usr/local/bin/
    else
        local d
        for d in ~/.local/bin ~/bin; do
            if test -d "$d"; then
                mv -v "$tool" "$d"/ && break
            fi
        done
    fi
}


main() {
    local tool cmd
    : "${XDG_CONFIG_HOME:="$HOME"/.config}"
    export XDG_CONFIG_HOME
    export NOW="$(date +%Y%m%d-%H%M)"
    declare -A HASHIVERSION=([vault]=1.6.1 [consul]=1.9.1 [nomad]=1.0.1 [terraform]=0.14.4 [packer]=1.6.6)
    _VER=($(_osid -s))
    OSID=$(_osid)
    OSID_NAME="${_VER[0]}"
    OSID_VERSION="${_VER[1]}"
    SUDO=''
    NOROOT=0
    GOINSTALL=/usr/local
    INSTALL_CONFIG=${INSTALL_CONFG:-0}
    CONFIG_ONLY=${CONFIG_ONLY:-0}
    INSTALL_VIM=${INSTALL_VIM:-0}
    INSTALL_VIM_CONFIG=${INSTALL_VIM_CONFIG:-0}
    INSTALL_GOLANG=${INSTALL_GOLANG:-0}
    INSTALL_GOLANG_TOOLS=${INSTALL_GOLANG_TOOLS:-0}
    INSTALL_NEOVIM=${INSTALL_NEOVIM:-0}
    INSTALL_EXTRAS=${INSTALL_EXTRAS:-0}
    IS_ROOT=0
    INSTALLS=()
    if test $(id -u) -ne 0; then
        IS_ROOT=1
        GOINSTALL="$HOME/.local"
        command -v sudo >/dev/null && SUDO='sudo -H' || NOROOT=1
    fi

    while [ $# -gt 0 ]; do
        cmd="$1"
        shift
        case "$cmd" in
            -h|--help) usage;  exit 0 ;;
            --config) INSTALL_CONFIG=1;;
            --no-config) INSTALL_CONFIG=0 ;;
            --no-vim) INSTALL_VIM=0 ;;
            --config-only) INSTALL_CONFIG=1; CONFIG_ONLY=1;;
            --hashitool)
                version="${1#*=}"
                tool="${tool%=$version}"
                download_hashitool "$tool" "$version"
                if ((IS_ROOT)); then
                    $SUDO mv "$tool" /usr/local/bin/
                else
                    for d in ~/.local/bni ~/bin; do
                        if test -d "$d"; then
                            mv "$tool" "$d"/ && break
                        fi
                    done
                fi
                ;;
            --vault|--nomad|--consul|--terraform|--packer)
                tool="${cmd#--}"
                download_hashitool "$tool" "${HASHIVERSION[$tool]}"
                ;;
            --vault=*|--nomad=*|--consul=*|--terraform=*|--packer=*)
                tool="${cmd#--}"
                version="${tool#*=}"
                tool="${tool%=$version}"
                download_hashitool "$tool" "$version"
                ;;
            --noroot|--no-root) SUDO=''; NOROOT=1;;
            --vim) INSTALL_VIM=1 ; INSTALLS+=(vim);;
            --vim-config) INSTALL_VIM_CONFIG=1 ;;
            --no-vim-config) INSTALL_VIM_CONFIG=0 ;;
            --extras) INSTALL_EXTRAS=1 ; INSTALLS+=(extras);;
            --no-extras) INSTALL_EXTRAS=0 ;;
            --no-golang-tools) INSTALL_GOLANG_TOOLS=0 ;;
            --golang-tools) INSTALL_GOLANG_TOOLS=1 ;;
            --no-golang) INSTALL_GOLANG=0;;
            --golang|--install-go*) INSTALL_GOLANG=1;;
            *)
                echo >&2 "Unknown command: $cmd"
                usage >&2
                exit 1
                ;;
        esac
    done
    if ! ((CONFIG_ONLY)); then

        if ! ((NOROOT)); then
            # setup some basics (curl, epel, etc)
            install_setup

            # neovim
            if ((INSTALL_VIM)); then
                install_vim
            fi
            if ((INSTALL_EXTRAS)); then
                install_extras
            fi
        fi
        # golang
        if ((INSTALL_GOLANG)); then
             install_golang "$GOINSTALL"
        fi

        if ((INSTALL_GOLANG_TOOLS)); then
            install_golang_tools
        fi
    fi

    if ((INSTALL_VIM_CONFIG)); then
        install_vim_config
    fi

    if ((INSTALL_CONFIG)); then
        install_config
    fi

    # shellcheck disable=SC2016
    echo >&2 'Logout and back in or source ~/.bashrc, or run exec -l $SHELL'
}
main "$@"
