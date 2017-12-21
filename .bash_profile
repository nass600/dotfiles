#! /bin/bash

# Include alias file (if present) containing aliases for ssh, etc.
if [ -f ~/.bash_aliases ]
then
    source ~/.bash_aliases
fi

# Include bashrc file (if present).
if [ -f ~/.bashrc ]
then
    source ~/.bashrc
fi

# Add tab completion for many Bash commands
if which brew > /dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    source "$(brew --prefix)/etc/bash_completion";
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion;
fi;

# Add homebrew python version to path (only macOS)
if [ -d "/usr/local/opt/python/libexec/bin" ]
    export PATH="/usr/local/opt/python/libexec/bin:$PATH"
fi;
