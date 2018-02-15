#! /bin/bash
# sourced by .bashrc

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# List

if [ -x /usr/bin/dircolors ]; then
    eval "`dircolors -b ~/.dir_colors`"
    alias ls='ls -Fh --color=auto'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
else
    eval "`gdircolors -b ~/.dir_colors`"
    alias ls='gls -GFh'
    alias ll='gls -alF --color=auto'
    alias la='gls -GA'
fi

# Grep

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Docker

alias doco='docker-compose'
alias docker-cli='docker rmi $(docker images -qf dangling=true)'
alias docker-clc='docker rm -v $(docker ps -aqf status=exited)'
alias docker-clv='docker volume rm $(docker volume ls -qf dangling=true)'
