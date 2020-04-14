# List
alias ls='gls -GFh'
alias ll='gls -alF --color=auto'
alias la='gls -GA'

# Grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Docker
alias doco='docker-compose'
alias docker-cli='docker rmi $(docker images -qf dangling=true)'
alias docker-clc='docker rm -v $(docker ps -aqf status=exited)'
alias docker-clv='docker volume rm $(docker volume ls -qf dangling=true)'
