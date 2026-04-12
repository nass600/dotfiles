# Dotfiles Modernisation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the `dotfiles` repo from a plain symlink collection into a fully self-contained chezmoi-managed provisioner that replaces `macos-setup` entirely.

**Architecture:** chezmoi owns dotfile templating, secrets, and change-triggered scripts. A `Brewfile` declares every package. A single `install.sh` bootstraps a fresh Mac from zero. The `macos-setup` repo is deprecated — everything lives here.

**Tech Stack:** chezmoi, Homebrew Bundle (Brewfile), zinit, Ghostty, micro, powerlevel10k, 1Password CLI

**Constraint:** Do not commit anything. All changes are local only.

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `install.sh` | Create | One-command bootstrap for fresh installs |
| `Brewfile` | Create | All packages, casks, MAS apps |
| `.chezmoi.toml.tmpl` | Create | chezmoi config with variables and 1Password wiring |
| `dot_gitconfig.tmpl` | Replace `.gitconfig` | Templated gitconfig (name, email from vars, editor → micro) |
| `dot_gitignore` | Replace `.gitignore` | Git global ignores |
| `dot_zprofile` | Replace `.zprofile` | Login shell PATH setup (Homebrew, pyenv) |
| `dot_zshrc` | Replace `.zshrc.local` | Full ZSH config with zinit (antigen removed) |
| `dot_p10k.zsh.local` | Rename `.p10k.zsh.local` | Powerlevel10k config (content unchanged) |
| `dot_npmrc.tmpl` | Create | npm registry auth via 1Password |
| `dot_config/ghostty/config` | Create | Ghostty terminal config |
| `dot_config/micro/settings.json` | Create | micro editor config |
| `run_once_before_install-xcode.sh` | Create | Installs Xcode CLT if missing |
| `run_once_macos-defaults.sh` | Create | All macOS `defaults write` settings (runs once) |
| `run_onchange_brew-bundle.sh.tmpl` | Create | Runs `brew bundle` whenever Brewfile changes |
| `README.md` | Rewrite | Fresh install + day-to-day update docs |
| `.vimrc` | Delete | Replaced by micro |
| `.zshrc.local` | Delete | Consolidated into `dot_zshrc` |

---

## Task 1: Remove deprecated files

**Files:**
- Delete: `.vimrc`
- Delete: `.zshrc.local`

- [ ] **Step 1: Delete `.vimrc`**

  Vundle and vim plugins are gone. micro is the new commit editor.

  ```sh
  rm /Users/nass600/Workspace/nass600/dotfiles/.vimrc
  ```

- [ ] **Step 2: Delete `.zshrc.local`**

  Its content will be fully consolidated into `dot_zshrc` in Task 6.

  ```sh
  rm /Users/nass600/Workspace/nass600/dotfiles/.zshrc.local
  ```

- [ ] **Step 3: Verify only expected files remain**

  ```sh
  ls -la /Users/nass600/Workspace/nass600/dotfiles/
  ```

  Expected: `.gitconfig`, `.gitignore`, `.p10k.zsh.local`, `.zprofile`, `LICENSE`, `README.md` — nothing else.

---

## Task 2: chezmoi config

**Files:**
- Create: `.chezmoi.toml.tmpl`

- [ ] **Step 1: Create `.chezmoi.toml.tmpl`**

  ```toml
  [data]
      name = "Ignacio Velazquez"
      email = "ivelazquez85@gmail.com"
      github_user = "nass600"

  [onepassword]
      command = "op"
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/.chezmoi.toml.tmpl`

- [ ] **Step 2: Verify file is valid TOML**

  ```sh
  cat /Users/nass600/Workspace/nass600/dotfiles/.chezmoi.toml.tmpl
  ```

  Expected: file contents printed cleanly, no parse errors visible.

---

## Task 3: Brewfile

**Files:**
- Create: `Brewfile`

Migrates all packages from `macos-setup/default.config.yml`. Adds: `ghostty`, `micro`, `chezmoi`, `zinit`. Removes: `iterm2`, `ansible`, `ansible-lint`.

- [ ] **Step 1: Create `Brewfile`**

  ```ruby
  # CLI Tools
  brew "automake"
  brew "awscli"
  brew "bat"
  brew "chezmoi"
  brew "coreutils"
  brew "exiftool"
  brew "ffmpeg"
  brew "fzf"
  brew "gh"
  brew "git"
  brew "gnu-tar"
  brew "htop"
  brew "libtool"
  brew "libuv"
  brew "media-info"
  brew "micro"
  brew "nvm"
  brew "openjdk"
  brew "pipx"
  brew "pyenv"
  brew "tesseract-lang"
  brew "uv"
  brew "wget"
  brew "zinit"

  # Casks
  cask "1password-cli"
  cask "aegisub"
  cask "betterdisplay"
  cask "claude-code"
  cask "cursor"
  cask "docker-desktop"
  cask "drivedx"
  cask "elmedia-player"
  cask "firefox"
  cask "font-maven-pro"
  cask "font-meslo-lg-nerd-font"
  cask "ghostty"
  cask "google-chrome"
  cask "istat-menus"
  cask "jdownloader"
  cask "logi-options+"
  cask "makemkv"
  cask "mkvtoolnix-app"
  cask "namechanger"
  cask "notion"
  cask "plex"
  cask "postman"
  cask "rar"
  cask "raycast"
  cask "sublime-text"
  cask "the-unarchiver"
  cask "transmission"
  cask "transmit"
  cask "whatsapp"
  cask "zoom"

  # Mac App Store
  mas "BetterSnapTool", id: 417375580
  mas "DaisyDisk", id: 411643860
  mas "Fantastical - Calendar & Tasks", id: 975937182
  mas "hide.me VPN", id: 953040671
  mas "Subtitle Extractor", id: 876111075
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/Brewfile`

- [ ] **Step 2: Verify Brewfile syntax**

  ```sh
  brew bundle check --file=/Users/nass600/Workspace/nass600/dotfiles/Brewfile
  ```

  Expected: lines like `The Brewfile's dependencies are satisfied.` or a list of missing packages. Any syntax error will show as an explicit error. Missing packages are expected and fine — this is a declaration of desired state, not a check of current state.

---

## Task 4: chezmoi scripts

**Files:**
- Create: `run_once_before_install-xcode.sh`
- Create: `run_onchange_brew-bundle.sh.tmpl`

- [ ] **Step 1: Create `run_once_before_install-xcode.sh`**

  ```sh
  #!/bin/sh
  # Installs Xcode Command Line Tools if not present.
  # chezmoi runs this once on fresh install (run_once_ prefix).

  if ! xcode-select -p &>/dev/null; then
      echo "Installing Xcode Command Line Tools..."
      xcode-select --install
      echo ""
      echo "IMPORTANT: Complete the Xcode CLT installation dialog, then re-run:"
      echo "  chezmoi apply"
      exit 1
  fi
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/run_once_before_install-xcode.sh`

  ```sh
  chmod +x /Users/nass600/Workspace/nass600/dotfiles/run_once_before_install-xcode.sh
  ```

- [ ] **Step 2: Create `run_onchange_brew-bundle.sh.tmpl`**

  The comment on line 2 embeds a hash of the Brewfile. chezmoi detects when this hash changes and re-runs the script automatically — this is the drift-prevention mechanism.

  ```sh
  #!/bin/sh
  # Runs brew bundle whenever the Brewfile changes.
  # {{ include "Brewfile" | sha256sum }}

  brew bundle --no-lock --file="{{ .chezmoi.sourceDir }}/Brewfile"
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/run_onchange_brew-bundle.sh.tmpl`

  ```sh
  chmod +x /Users/nass600/Workspace/nass600/dotfiles/run_onchange_brew-bundle.sh.tmpl
  ```

- [ ] **Step 3: Verify both scripts exist and are executable**

  ```sh
  ls -la /Users/nass600/Workspace/nass600/dotfiles/run_*
  ```

  Expected: both files listed with `-rwxr-xr-x` permissions.

---

## Task 5: macOS defaults script

**Files:**
- Create: `run_once_macos-defaults.sh`

Ports all settings from `macos-setup/default.config.yml`. The `run_once_` prefix means chezmoi runs this exactly once on fresh install.

**Important:** After creating this file, verify each setting manually on the current machine (see Step 2). Remove any that don't work on macOS 15 Sequoia.

- [ ] **Step 1: Create `run_once_macos-defaults.sh`**

  ```sh
  #!/bin/sh
  # Applies macOS system defaults.
  # chezmoi runs this once on fresh install (run_once_ prefix).
  # Verified on macOS 15 Sequoia.

  echo "Applying macOS defaults..."

  # --- Interface ---
  defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

  # --- Dock ---
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock orientation -string "left"
  defaults write com.apple.dock tilesize -integer 30
  defaults write com.apple.dock show-recents -bool false

  # --- Users & Groups ---
  defaults write com.apple.loginwindow GuestEnabled -bool false

  # --- Trackpad ---
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
  defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5

  # --- Clock ---
  # NOTE: Verify this key still works on macOS 15 — clock format keys have shifted
  defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm"

  # --- Finder ---
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.finder NewWindowTarget -string "PfHm"

  # --- Desktop Services ---
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Restart affected apps
  killall Dock
  killall Finder

  echo "macOS defaults applied. Some settings may require logout to take effect."
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/run_once_macos-defaults.sh`

  ```sh
  chmod +x /Users/nass600/Workspace/nass600/dotfiles/run_once_macos-defaults.sh
  ```

- [ ] **Step 2: Verify each setting on macOS 15 Sequoia**

  Run the script in dry-run mode (read each line and apply one at a time) and confirm the setting appears in System Settings:

  ```sh
  # Test a sample — check if Dark Mode setting sticks
  defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
  # Open System Settings → Appearance → verify Dark is selected

  # Test clock format
  defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm"
  # Check menu bar clock — if format doesn't change, remove this line from the script
  ```

  For any setting that does not produce the expected result in System Settings, **remove that line** from `run_once_macos-defaults.sh`. Better to have 10 confirmed working settings than 20 that silently fail.

---

## Task 6: Dotfiles — gitconfig and gitignore

**Files:**
- Replace: `.gitconfig` → `dot_gitconfig.tmpl`
- Replace: `.gitignore` → `dot_gitignore`

- [ ] **Step 1: Create `dot_gitconfig.tmpl`**

  Name and email are now chezmoi template variables. Editor changes from `vim` to `micro`.

  ```
  [init]
      defaultBranch = main
  [user]
      name = {{ .name }}
      email = {{ .email }}
  [github]
      user = {{ .github_user }}
  [color]
      ui = auto
  [core]
      editor = micro
      excludesfile = ~/.gitignore
  [web]
      browser = google-chrome
  [pull]
      default = current
  [push]
      default = current
  [alias]
      kill = "!f(){ git branch -D \"$1\";  git push origin --delete \"$1\"; };f"
      co = checkout
      br = branch
      ci = commit
      st = status
      pl = pull
      ps = push
      lg = lg1
      lg1 = lg1-specific --all
      lg2 = lg2-specific --all
      lg3 = lg3-specific --all
      lg1-specific = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'
      lg2-specific = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'
      lg3-specific = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n'
  [remote "origin"]
      fetch = +refs/pull/*/head:refs/remotes/origin/pr/*
  [remote "upstream"]
      fetch = +refs/pull/*/head:refs/remotes/upstream/pr/*
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/dot_gitconfig.tmpl`

- [ ] **Step 2: Delete the old `.gitconfig`**

  ```sh
  rm /Users/nass600/Workspace/nass600/dotfiles/.gitconfig
  ```

- [ ] **Step 3: Rename `.gitignore` to `dot_gitignore`**

  ```sh
  mv /Users/nass600/Workspace/nass600/dotfiles/.gitignore /Users/nass600/Workspace/nass600/dotfiles/dot_gitignore
  ```

- [ ] **Step 4: Verify**

  ```sh
  ls /Users/nass600/Workspace/nass600/dotfiles/dot_git*
  ```

  Expected: `dot_gitconfig.tmpl` and `dot_gitignore` — no `.gitconfig` or `.gitignore` remaining.

---

## Task 7: Dotfiles — zshrc with zinit

**Files:**
- Create: `dot_zshrc`
- Delete: `.zshrc.local` (already done in Task 1)
- Replace: `.zprofile` → `dot_zprofile`

This is the largest change. The `viasite-ansible.zsh` role used to generate `~/.zshrc` and source `~/.zshrc.local`. Now `dot_zshrc` owns the entire ZSH config. zinit replaces antigen. All content from `.zshrc.local` is consolidated here.

- [ ] **Step 1: Create `dot_zshrc`**

  ```zsh
  # --- Powerlevel10k instant prompt ---
  # Must be at the very top, before anything that may produce output.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
      source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

  # --- zinit bootstrap ---
  ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  if [ ! -d "$ZINIT_HOME" ]; then
      mkdir -p "$(dirname $ZINIT_HOME)"
      git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  fi
  source "${ZINIT_HOME}/zinit.zsh"

  # --- Plugins: Oh My Zsh snippets ---
  zinit snippet OMZL::git.zsh
  zinit snippet OMZP::git
  zinit snippet OMZP::brew
  zinit snippet OMZP::docker
  zinit snippet OMZP::docker-compose
  zinit snippet OMZP::macos
  zinit snippet OMZP::npm
  zinit snippet OMZP::nvm
  zinit snippet OMZP::pyenv
  zinit snippet OMZP::aws
  zinit snippet OMZP::fzf

  # --- Plugins: GitHub ---
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light joshjon/bliss-dircolors

  # --- Prompt: Powerlevel10k ---
  zinit ice depth=1
  zinit light romkatv/powerlevel10k
  [[ -f ~/.p10k.zsh.local ]] && source ~/.p10k.zsh.local

  # --- Completions ---
  autoload -Uz compinit && compinit

  # --- Dircolors ---
  _BLISS_DIRCOLORS="${ZINIT[PLUGINS_DIR]}/joshjon---bliss-dircolors/bliss.dircolors"
  [[ -f "$_BLISS_DIRCOLORS" ]] && eval "$(gdircolors $_BLISS_DIRCOLORS)"
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

  # --- Language ---
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8

  # --- Homebrew (Apple Silicon) ---
  if [ -d "/opt/homebrew/bin" ]; then
      export PATH="/opt/homebrew/bin:$PATH"
      export PATH="/opt/homebrew/sbin:$PATH"
  fi

  # --- NVM ---
  export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"

  # --- Pyenv ---
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"

  # --- Poetry / pipx ---
  export PATH="$HOME/.local/bin:$PATH"

  # --- Tesseract ---
  export TESSDATA_PREFIX="/opt/homebrew/share/tessdata"

  # --- Aliases ---
  alias doco="docker compose"
  alias egrep="egrep --color=always"
  alias fgrep="fgrep --color=always"
  alias grep="grep --color=always"
  alias la="gls -GA --color=always"
  alias ll="gls -alF --color=always"
  alias ls="gls -GFh --color=always"
  alias main="git pull origin main --rebase && git fetch --tags"

  # --- Zsh syntax highlighting theme ---
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=9,bold'
  ZSH_HIGHLIGHT_STYLES[correct-subtle]='fg=46'
  ZSH_HIGHLIGHT_STYLES[incorrect-subtle]='fg=9'
  ZSH_HIGHLIGHT_STYLES[subcommand]='fg=219,bold'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=39,bold'
  ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=39,bold'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=39,bold'
  ZSH_HIGHLIGHT_STYLES[function]='fg=46,bold'
  ZSH_HIGHLIGHT_STYLES[command]='fg=39,bold'
  ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=39,bold'
  ZSH_HIGHLIGHT_STYLES[path]='fg=214'
  ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=226'
  ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=226'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=46'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=46'
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/dot_zshrc`

- [ ] **Step 2: Rename `.zprofile` to `dot_zprofile`**

  The `.zprofile` content (Homebrew PATH, pyenv for login shells) is kept as-is.

  ```sh
  mv /Users/nass600/Workspace/nass600/dotfiles/.zprofile /Users/nass600/Workspace/nass600/dotfiles/dot_zprofile
  ```

- [ ] **Step 3: Verify**

  ```sh
  ls /Users/nass600/Workspace/nass600/dotfiles/dot_z*
  ```

  Expected: `dot_zprofile` and `dot_zshrc` — no `.zprofile` or `.zshrc.local` remaining.

---

## Task 8: Dotfiles — p10k and npmrc

**Files:**
- Rename: `.p10k.zsh.local` → `dot_p10k.zsh.local`
- Create: `dot_npmrc.tmpl`

- [ ] **Step 1: Rename `.p10k.zsh.local` to `dot_p10k.zsh.local`**

  Content is unchanged — this is purely a rename to chezmoi's naming convention.

  ```sh
  mv /Users/nass600/Workspace/nass600/dotfiles/.p10k.zsh.local /Users/nass600/Workspace/nass600/dotfiles/dot_p10k.zsh.local
  ```

- [ ] **Step 2: Create `dot_npmrc.tmpl`**

  Replaces the Ansible `lineinfile` task that wrote the GitHub npm registry token.

  ```
  //npm.pkg.github.com/:_authToken={{ onepasswordRead "op://Personal/GH_NPM_REGISTRY/credential" }}
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/dot_npmrc.tmpl`

- [ ] **Step 3: Verify**

  ```sh
  ls /Users/nass600/Workspace/nass600/dotfiles/dot_p10k* /Users/nass600/Workspace/nass600/dotfiles/dot_npmrc*
  ```

  Expected: both files present.

---

## Task 9: Tool configs — Ghostty and micro

**Files:**
- Create: `dot_config/ghostty/config`
- Create: `dot_config/micro/settings.json`

- [ ] **Step 1: Create `dot_config/ghostty/config`**

  Uses the Meslo Nerd Font already in the Brewfile (`font-meslo-lg-nerd-font`).

  ```sh
  mkdir -p /Users/nass600/Workspace/nass600/dotfiles/dot_config/ghostty
  ```

  ```
  # Font
  font-family = MesloLGS Nerd Font Mono
  font-size = 14

  # Theme
  theme = dark:Catppuccin Mocha,light:Catppuccin Latte

  # Window
  window-padding-x = 8
  window-padding-y = 8
  window-decoration = false

  # Shell
  shell-integration = zsh

  # Cursor
  cursor-style = block
  cursor-style-blink = false

  # Scrollback
  scrollback-limit = 10000
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/dot_config/ghostty/config`

- [ ] **Step 2: Create `dot_config/micro/settings.json`**

  ```sh
  mkdir -p /Users/nass600/Workspace/nass600/dotfiles/dot_config/micro
  ```

  ```json
  {
      "colorscheme": "monokai",
      "tabsize": 4,
      "softtabs": true,
      "autoclose": true,
      "mouse": true,
      "saveundo": true
  }
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/dot_config/micro/settings.json`

- [ ] **Step 3: Verify both configs exist**

  ```sh
  find /Users/nass600/Workspace/nass600/dotfiles/dot_config -type f
  ```

  Expected:
  ```
  dotfiles/dot_config/ghostty/config
  dotfiles/dot_config/micro/settings.json
  ```

---

## Task 10: Bootstrap script

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Create `install.sh`**

  ```sh
  #!/bin/sh
  set -e

  echo "Starting dotfiles installation..."

  # --- Xcode Command Line Tools ---
  if ! xcode-select -p &>/dev/null; then
      echo "Installing Xcode Command Line Tools..."
      xcode-select --install
      echo ""
      echo "Complete the Xcode CLT installation dialog, then re-run this script."
      exit 0
  fi

  # --- Homebrew ---
  if ! command -v brew &>/dev/null; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  # --- chezmoi ---
  if ! command -v chezmoi &>/dev/null; then
      echo "Installing chezmoi..."
      brew install chezmoi
  fi

  # --- Apply dotfiles ---
  echo "Applying dotfiles..."
  chezmoi init --apply nass600/dotfiles

  echo ""
  echo "Done. Open a new terminal session for all changes to take effect."
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/install.sh`

  ```sh
  chmod +x /Users/nass600/Workspace/nass600/dotfiles/install.sh
  ```

- [ ] **Step 2: Verify the script is executable and has no syntax errors**

  ```sh
  sh -n /Users/nass600/Workspace/nass600/dotfiles/install.sh && echo "Syntax OK"
  ```

  Expected: `Syntax OK`

---

## Task 11: README

**Files:**
- Rewrite: `README.md`

- [ ] **Step 1: Rewrite `README.md`**

  ```markdown
  # dotfiles

  My personal macOS setup. One command provisions a fresh MacBook from zero.
  Manages dotfiles, packages, macOS settings, and secrets.

  > Tested on macOS 15 Sequoia (Apple Silicon)

  ## Fresh install

  On a brand-new Mac, run:

  \```sh
  curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh | sh
  \```

  This will:
  1. Install Xcode Command Line Tools
  2. Install Homebrew
  3. Install chezmoi
  4. Clone this repo and apply all dotfiles, packages, and macOS settings

  ## Day-to-day workflow

  ### Adding a new package

  \```sh
  # Edit the Brewfile (in your editor or via chezmoi)
  chezmoi edit ~/Brewfile

  # Apply — chezmoi detects the change and runs brew bundle automatically
  chezmoi apply
  \```

  ### Editing a dotfile

  \```sh
  chezmoi edit ~/.zshrc    # opens the source file in chezmoi's repo
  chezmoi apply            # applies the change to your home dir
  \```

  ### Pushing changes to GitHub

  \```sh
  chezmoi cd               # navigate to the chezmoi source repo (~/.local/share/chezmoi)
  git add -A && git commit -m "..." && git push
  \```

  ### Checking for drift

  \```sh
  brew bundle check        # lists packages installed but not in Brewfile
  brew bundle cleanup --dry-run   # shows what would be removed to match Brewfile exactly
  \```

  ### Updating all packages

  \```sh
  brew update && brew upgrade && brew bundle
  \```

  ## Repo structure

  \```
  dotfiles/
  ├── install.sh                          # fresh install bootstrap
  ├── Brewfile                            # all packages, casks, MAS apps
  ├── .chezmoi.toml.tmpl                  # chezmoi config (variables, 1Password)
  ├── dot_gitconfig.tmpl                  # → ~/.gitconfig
  ├── dot_gitignore                       # → ~/.gitignore
  ├── dot_zprofile                        # → ~/.zprofile
  ├── dot_zshrc                           # → ~/.zshrc
  ├── dot_p10k.zsh.local                  # → ~/.p10k.zsh.local
  ├── dot_npmrc.tmpl                      # → ~/.npmrc (secret from 1Password)
  ├── dot_config/
  │   ├── ghostty/config                  # → ~/.config/ghostty/config
  │   └── micro/settings.json             # → ~/.config/micro/settings.json
  ├── run_once_before_install-xcode.sh    # runs once: installs Xcode CLT
  ├── run_once_macos-defaults.sh          # runs once: applies macOS system settings
  └── run_onchange_brew-bundle.sh.tmpl    # runs when Brewfile changes: brew bundle
  \```

  ## chezmoi quick reference

  | Prefix | Meaning |
  |---|---|
  | `dot_` | Becomes `.filename` in home dir |
  | `.tmpl` | Processed as template (variables/secrets) |
  | `run_once_` | Runs one time on fresh install |
  | `run_onchange_` | Runs whenever the file content changes |

  ## Author

  [Ignacio Velazquez](http://ignaciovelazquez.es)
  ```

  Save to `/Users/nass600/Workspace/nass600/dotfiles/README.md`

---

## Task 12: Final verification

- [ ] **Step 1: Verify complete file structure**

  ```sh
  find /Users/nass600/Workspace/nass600/dotfiles -not -path '*/.git/*' -not -path '*/docs/*' | sort
  ```

  Expected output:
  ```
  dotfiles/
  dotfiles/.chezmoi.toml.tmpl
  dotfiles/Brewfile
  dotfiles/LICENSE
  dotfiles/README.md
  dotfiles/dot_config/ghostty/config
  dotfiles/dot_config/micro/settings.json
  dotfiles/dot_gitconfig.tmpl
  dotfiles/dot_gitignore
  dotfiles/dot_npmrc.tmpl
  dotfiles/dot_p10k.zsh.local
  dotfiles/dot_zprofile
  dotfiles/dot_zshrc
  dotfiles/install.sh
  dotfiles/run_once_before_install-xcode.sh
  dotfiles/run_once_macos-defaults.sh
  dotfiles/run_onchange_brew-bundle.sh.tmpl
  ```

  No `.gitconfig`, `.gitignore`, `.vimrc`, `.zshrc.local`, `.zprofile`, `.p10k.zsh.local` should remain.

- [ ] **Step 2: Verify chezmoi can parse the source directory**

  Install chezmoi if not present: `brew install chezmoi`

  ```sh
  chezmoi --source /Users/nass600/Workspace/nass600/dotfiles diff
  ```

  Expected: chezmoi lists what it would change (or nothing if already applied). No template parse errors. If you see `Error:` lines, fix the indicated file before proceeding.

- [ ] **Step 3: Verify Brewfile has no syntax errors**

  ```sh
  brew bundle check --file=/Users/nass600/Workspace/nass600/dotfiles/Brewfile 2>&1 | head -5
  ```

  Expected: either `dependencies are satisfied` or a list of missing packages — both are fine. An explicit `Error:` line means a syntax problem in the Brewfile.

- [ ] **Step 4: Verify install.sh has no syntax errors**

  ```sh
  sh -n /Users/nass600/Workspace/nass600/dotfiles/install.sh && echo "OK"
  ```

  Expected: `OK`

- [ ] **Step 5: Confirm no files from macos-setup are needed**

  The following files in `macos-setup` are now fully replaced and the repo can be archived:
  - `main.yml` → replaced by `install.sh` + chezmoi scripts
  - `default.config.yml` → replaced by `Brewfile` + `run_once_macos-defaults.sh`
  - `requirements.yml` → no Ansible roles needed
  - `bin/install` → replaced by `install.sh`
  - All dotfiles → migrated to `dotfiles` repo
