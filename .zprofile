# NVM
export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
