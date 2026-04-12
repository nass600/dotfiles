# dotfiles

[![macos](<https://img.shields.io/badge/macos_15_(sequoia)-white?style=for-the-badge&logo=apple&logoColor=black>)]()
[![GitHub tag](https://img.shields.io/github/tag/nass600/dotfiles.svg?style=for-the-badge&logo=github)]()

My personal macOS setup. One command provisions a fresh MacBook from zero. Manages dotfiles, packages, macOS settings, and secrets — all in a single repo.

> Tested on macOS 15 Sequoia (Apple Silicon)

## Fresh install

On a brand-new Mac, run:

```sh
curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh | sh
```

This will:

1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install chezmoi
4. Clone this repo and apply all dotfiles, packages, and macOS settings in one pass

## Day-to-day workflow

### Adding a new package

```sh
# Edit the Brewfile
chezmoi edit ~/Brewfile

# Apply — chezmoi detects the change and runs `brew bundle` automatically
chezmoi apply
```

No "remember to commit later" step. The Brewfile *is* the installer — if it's not in the file, it's not installed.

### Editing a dotfile

```sh
chezmoi edit ~/.zshrc   # opens the source file in chezmoi's repo
chezmoi apply           # applies the change to your home dir
```

### Pushing changes to GitHub

```sh
chezmoi cd              # navigate to the chezmoi source repo
git add -A && git commit -m "..." && git push
```

### Checking for drift

```sh
brew bundle check                 # lists packages installed but not in Brewfile
brew bundle cleanup --dry-run     # shows what would be removed to match Brewfile exactly
```

### Updating all packages

```sh
brew update && brew upgrade && brew bundle
```

## Repo structure

```
dotfiles/
├── install.sh                          # fresh install bootstrap
├── Brewfile                            # all packages, casks, MAS apps
├── .chezmoi.toml.tmpl                  # chezmoi config (variables, 1Password)
│
├── dot_gitconfig.tmpl                  # → ~/.gitconfig
├── dot_gitignore                       # → ~/.gitignore
├── dot_zprofile                        # → ~/.zprofile
├── dot_zshrc                           # → ~/.zshrc (zinit-managed)
├── dot_p10k.zsh.local                  # → ~/.p10k.zsh.local
├── dot_npmrc.tmpl                      # → ~/.npmrc (secret from 1Password)
│
├── dot_config/
│   ├── ghostty/config                  # → ~/.config/ghostty/config
│   └── micro/settings.json             # → ~/.config/micro/settings.json
│
├── run_once_before_install-xcode.sh    # runs once: installs Xcode CLT
├── run_once_macos-defaults.sh          # runs once: applies macOS system settings
└── run_onchange_brew-bundle.sh.tmpl    # runs when Brewfile changes: brew bundle
```

## Tech stack

| Tool | Purpose |
|---|---|
| **chezmoi** | Dotfiles manager (templating, secrets, change-triggered scripts) |
| **Homebrew + Brewfile** | Package management (CLI tools, casks, Mac App Store apps) |
| **zinit** | ZSH plugin manager |
| **powerlevel10k** | ZSH prompt |
| **Ghostty** | Terminal emulator |
| **micro** | Default git commit editor |
| **1Password CLI** | Secrets backend (integrates natively with chezmoi) |

## chezmoi quick reference

| Prefix | Meaning |
|---|---|
| `dot_` | Becomes `.filename` in home dir |
| `.tmpl` | Processed as template (variables, secrets) |
| `run_once_` | Runs one time on fresh install |
| `run_onchange_` | Runs whenever the file's content changes |

## License

[MIT](LICENSE)

## Author

[Ignacio Velazquez](http://ignaciovelazquez.es)
