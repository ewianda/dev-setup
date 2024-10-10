# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
export HISTCONTROL=ignoredups:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000
# avoid duplicates..


# After each command, save and reload history


# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi



# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

. /usr/lib/git-core/git-sh-prompt

export GIT_PS1_SHOWCOLORHINTS=true # Option for git-prompt.sh to show branch name in color
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"

# Terminal Prompt:
# Include git branch, use PROMPT_COMMAND (not PS1) to get color output (see git-prompt.sh for more)
# export PROMPT_COMMAND='__git_ps1 "\u@\h:\w" "\\\$ "'
export PROMPT_COMMAND='__git_ps1 "\w" "\n\\\$ "'
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"



# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
export WORKON_HOME=/home/ewianda/.virtualenvs
if [ -f '/usr/local/bin/virtualenvwrapper.sh' ]; then . '/usr/local/bin/virtualenvwrapper.sh'; fi
export EDITOR=vim

# The username to the postgres instance
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$PATH:$HOME/bin"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$PATH:$HOME/.local/bin"
fi

export GOPATH=$HOME/go
export GOBIN=$HOME/go/bin

export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin


alias docker_clean='docker network prune -f || true && docker kill $(docker ps -q)'

#export PATH=$PATH:$(go env GOPATH)/bin
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export FZF_DEFAULT_COMMAND='rg --files --follow --no-ignore-vcs --hidden -g "!{node_modules/*,.git/*,bazel-*}"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
#export PROMPT_COMMAND="history -a; history -n"
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export BAZEL_BUILD_MATCH_PATTERN__test='(.*_test|test_suite|pytest|py_library)'
export BAZEL_QUERY_MATCH_PATTERN__test='(test|test_suite|pytest)'
export BAZEL_BUILD_MATCH_PATTERN_RUNTEST__bin='(.*_(binary|test)|test_suite|pytest|py_library)'
export BAZEL_QUERY_MATCH_PATTERN_RUNTEST__bin='(binary|test|pytest)'
export ANDROID_SDK=/home/ewianda/Android/Sdk
export PATH=$PATH:/home/ewianda/Android/Sdk/platform-tools/


export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PATH:$PYENV_ROOT/bin"
#eval "$(pyenv init --path)" 
#eval "$(pyenv init -)"
#eval "$(pyenv virtualenv-init -)"

alias bstack='f() { git reflog | grep checkout | cut -d " " -f 8 | uniq | head ${1} | cat -n  };f'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/ewianda/google-cloud-sdk/path.bash.inc' ]; then . '/home/ewianda/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/ewianda/google-cloud-sdk/completion.bash.inc' ]; then . '/home/ewianda/google-cloud-sdk/completion.bash.inc'; fi
export PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
export LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda-11.6/lib64:/usr/local/cuda-11.2/lib64/:/usr/local/cuda-11.6/targets/x86_64-linux/lib64/:/usr/local/cuda-11.6/targets/x86_64-linux/lib:/usr/lib/x86_64-linux-gnu
#export PAGER="vim -R +AnsiEsc"

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/bash/__tabtab.bash ] && . ~/.config/tabtab/bash/__tabtab.bash || true
