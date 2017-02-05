#! /bin/bash
# sourced by .bash_profile

# Alias definitions
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# Add tab completion for many Bash commands
if which brew > /dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
	source "$(brew --prefix)/etc/bash_completion";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Colors for dark terminals
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

############################################################
# Powerline configuration
############################################################

powerline_info=$(pip show powerline-status | grep Location)
if [ -n "$powerline_info" ]; then
    powerline_repo=${powerline_info#Location: }
    powerline-daemon -q
    POWERLINE_BASH_CONTINUATION=1
    POWERLINE_BASH_SELECT=1
    . ${powerline_repo}/powerline/bindings/bash/powerline.sh
fi