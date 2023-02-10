. $HOME/.dotfiles/zsh/powerlevel9k.zsh

# Colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Language
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# NVM
export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh

# Fast theme zsh-syntax-highlighting
if { fast-theme -l | grep -v -q 'clean'; }; then
    fast-theme -q 'clean'
fi

# Aliases
. $HOME/.dotfiles/zsh/aliases.zsh