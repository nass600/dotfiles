# dotfiles

[![macos](<https://img.shields.io/badge/macos_15_(sequoia)-white?style=for-the-badge&logo=apple&logoColor=black>)]()
[![GitHub tag](https://img.shields.io/github/tag/nass600/dotfiles.svg?style=for-the-badge&logo=github)]()

My personal macOS setup. One command provisions a fresh MacBook from zero: dotfiles, packages, macOS settings, language runtimes, editor extensions and secrets, for either of my two machines.

> Verified on macOS 15 Sequoia (Apple Silicon)

## Fresh install

### Before you start

**Nothing needs to be installed first.** Finish the macOS setup assistant, connect to the internet and open Terminal. The script installs everything else itself, including Homebrew, the Xcode Command Line Tools and 1Password.

What it cannot do is know your credentials. Have these at hand:

| You need | Used for | Tip |
|---|---|---|
| Your **macOS password** | Asked once, at the start | The account must be an administrator |
| Your **1Password sign-in** | Secrets and ssh keys | Emergency Kit, or another signed-in device to scan a QR code from |
| Your **Apple ID** | App Store apps in the `Brewfile` | Sign in during the macOS setup assistant and this pause disappears |
| **NAS and router addresses and ssh ports** | The `gt500` and `router` ssh aliases | Leave blank to skip an alias |

Optional, from the old machine: a copy of `~/.claude/projects` (Claude Code memory) and `~/.aws` (AWS credentials). Neither is in this repo.

### Where it stops and waits for you

The run is unattended except for these moments. Each one tells you exactly what to do and re-checks when you press Enter.

| When | What you do |
|---|---|
| Start | Type your macOS password |
| After 1Password is installed (a few minutes in) | Sign in, then enable **Integrate with 1Password CLI** and **Use the SSH agent** under *Settings → Developer*, and approve the Touch ID prompt |
| Before the dotfiles are applied | Answer: which machine (`personal` / `work`), NAS address and port, router address and port |
| During package install, only if not already signed in | Sign in to the App Store |
| During tool install | Approve 1Password's ssh key prompts for GitHub |
| End | Approve the GitHub CLI sign-in in the browser |

### Run it

On a brand-new Mac, open Terminal and run:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh)"
```

Use this exact form. Piping into `sh` (`curl … | sh`) detaches the terminal, and the Homebrew installer then refuses to run.

What happens, in order:

1. Asks for your password once and keeps the session alive for the whole run
2. Installs Homebrew, which installs the Xcode Command Line Tools on its own
3. Installs chezmoi, the GitHub CLI and 1Password
4. **Pause:** opens 1Password and waits until it can hand over secrets and ssh keys (see the table above)
5. Asks which machine this is (`personal` or `work`) and for the home network hosts
6. Applies everything: dotfiles, macOS defaults, Homebrew packages, then language runtimes and tools
7. **Pause:** if App Store apps are missing, opens the App Store and waits for you to sign in
8. Signs the GitHub CLI in through the browser
9. Prints a readiness report and the short list of things left to do by hand

A full run takes 30 to 60 minutes, most of it downloads. If any step fails, fix the cause and run `chezmoi apply` again. Every script retries until it passes.

### Check a machine without changing it

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh)" -- --check
```

Prints one line per requirement (Homebrew, 1Password CLI and SSH agent, GitHub access, whether the home directory matches the repo) and exits non-zero if anything needs attention. Safe to run before or after an install.

### After the install

The script ends with this list too:

- Open a new terminal so the new shell config loads
- Restore Claude Code memory into `~/.claude/projects`
- On the personal Mac, restore the JDownloader backup (see below)
- Sign in to AWS (`aws configure sso`, or restore `~/.aws`)
- Launch Docker Desktop once and accept its terms
- Grant app permissions as they ask: Raycast, BetterSnapTool, iStat Menus, Logi Options+
- Set up the desktop grid: see [Desktop grid (Lattice)](#desktop-grid-lattice)
- Log out and back in for the remaining macOS settings

### Desktop grid (Lattice)

macOS desktops are a single row. [Lattice](https://github.com/nass600/lattice) lays the existing ones out as a grid, so Mission Control and dragging windows between desktops keep working.

| Keys | Action |
|---|---|
| Ctrl+Cmd+arrows | Move one desktop in the grid |
| Ctrl+Cmd+G | Show the grid; press a number to jump |

It is built from source from a fork that adds configurable hotkeys, overview settings and start at login (`"startAtLogin": true` in its config, so no separate login item is needed). The version is pinned in `.chezmoidata/runtimes.toml`; its settings are in `dot_config/lattice/config.json`. To update, tag the fork, change the version and run `chezmoi apply`.

Three things macOS will not let a script do, so they are manual once per Mac:

- Enable **Lattice** under *Privacy & Security → Accessibility*. Repeat after each Lattice update, because a locally built app counts as new.
- Create the desktops in Mission Control. Lattice arranges the ones that exist; it does not create them.
- Turn on *Accessibility → Display → Reduce motion*. Without it macOS slides sideways even when you move up or down.

### App settings that are not plain files

Most app config is applied by chezmoi. Two cases work differently:

| App | How its settings travel |
|---|---|
| **MKVToolNix** | Seeded from this repo on first install (`Library/Preferences/bunkus.org/mkvtoolnix-gui/`). The app rewrites the file afterwards, so chezmoi leaves it alone once it exists. To capture new defaults, copy the live file back into the repo |
| **JDownloader** (personal Mac) | A binary backup holding accounts and settings, kept in iCloud Drive under `Config/jDownloader/`. **Before wiping:** *Settings → Backup → Create backup* and save it there. **After installing:** *Settings → Backup → Restore backup* |

### Testing a branch

To try changes on a machine before merging them:

```sh
DOTFILES_BRANCH=my-branch sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/my-branch/install.sh)"
```

On a machine that is already set up, preview instead of applying: `chezmoi diff`.

## Two machines

`chezmoi init` asks once which machine it is running on and remembers the answer in `~/.config/chezmoi/chezmoi.toml`, which is never committed. Templates read it as `.machine`.

| What differs | Where |
|---|---|
| Apps | `Brewfile` is shared; `Brewfile.personal` (JDownloader) and `Brewfile.work` (Slack, Zoom) add to it |
| Prompt accent colour | `[prompt.<machine>]` in `.chezmoidata/runtimes.toml` |
| Global tools | `[runtimes.<machine>]` in `.chezmoidata/runtimes.toml` |

It also asks for the NAS and router addresses used by the `gt500` and `router` ssh aliases. Those are the same on both machines but stay out of this public repo, so they are stored in the local chezmoi config too. A blank answer skips the alias.

To change any answer later: `chezmoi init --prompt`.

## Day-to-day workflow

### Adding a package

```sh
chezmoi cd                      # jump to this repo
$EDITOR Brewfile                # or Brewfile.personal / Brewfile.work
chezmoi apply                   # detects the change and runs `brew bundle`
```

The Brewfiles *are* the installer. If it's not in a file, it's not part of the setup.

### Adding a runtime, global tool or editor extension

Edit `.chezmoidata/runtimes.toml` and run `chezmoi apply`. Node comes from nvm, Python from pyenv, CLI tools from `uv tool` and `pipx`, extensions from the `cursor` CLI.

### Editing a dotfile

```sh
chezmoi edit ~/.zshrc   # opens the source file in this repo
chezmoi diff            # see what would change
chezmoi apply           # write it to your home dir
```

### Checking for drift

```sh
brewdrift                       # installed, but declared in neither Brewfile
brew bundle check --verbose     # declared, but not installed (run inside `chezmoi cd`)
```

### Updating all packages

```sh
brew update && brew upgrade
```

## Repo structure

```
dotfiles/
├── install.sh                                 # fresh-install bootstrap
├── Brewfile                                   # packages for every machine
├── Brewfile.personal / Brewfile.work          # packages for one machine
├── .chezmoi.toml.tmpl                         # init prompts: machine, home network hosts
├── .chezmoidata/runtimes.toml                 # runtimes, global tools, extensions, prompt colours
├── .chezmoiignore                             # keeps repo files out of $HOME
│
├── dot_zshrc / dot_zprofile                   # → ~/.zshrc, ~/.zprofile (zinit-managed)
├── dot_p10k.zsh.local.tmpl                    # → ~/.p10k.zsh.local (accent per machine)
├── dot_gitconfig.tmpl / dot_gitignore         # → ~/.gitconfig, ~/.gitignore
├── private_dot_npmrc.tmpl                     # → ~/.npmrc (token from 1Password)
├── dot_config/ghostty, micro, lattice          # → ~/.config/...
├── private_dot_ssh/                           # → ~/.ssh/config (1Password agent, gt500, router) + router public key
├── private_dot_claude/                        # → ~/.claude/CLAUDE.md, settings.json
├── Library/Application Support/Cursor/User/   # → Cursor settings.json
├── Library/Preferences/bunkus.org/            # → MKVToolNix GUI defaults
│
├── run_once_after_10-macos-defaults.sh        # macOS system settings
├── run_onchange_after_20-brew-bundle.sh.tmpl  # brew bundle, on any Brewfile change
├── run_onchange_after_30-runtimes.sh.tmpl     # node, python, uv tools, pipx, extensions
└── run_onchange_after_40-lattice.sh.tmpl      # builds and installs the desktop-grid app
```

Files with a `create_` prefix (Claude, Cursor and MKVToolNix settings) are written only when missing, because those apps rewrite them.

## What is deliberately not here

This repo is public, so anything that describes private infrastructure stays out:

- **Claude Code memory** (`~/.claude/projects/`). Back it up separately before wiping a machine.
- **Network details.** The NAS and router addresses are asked for at init and live only in the local chezmoi config.
- **Secrets.** They are read from 1Password at apply time; only the item path is in the repo.

## Tech stack

| Tool | Purpose |
|---|---|
| **chezmoi** | Dotfiles manager (templating, secrets, change-triggered scripts) |
| **Homebrew + Brewfile** | Package management (CLI tools, casks, Mac App Store apps) |
| **zinit** | ZSH plugin manager |
| **powerlevel10k** | ZSH prompt |
| **Ghostty** | Terminal emulator |
| **micro** | Default git commit editor |
| **1Password** | Secrets backend and SSH agent |
| **nvm, pyenv, uv, pipx** | Language runtimes and global tools |

## chezmoi quick reference

| Prefix | Meaning |
|---|---|
| `dot_` | Becomes `.filename` in home dir |
| `private_` | Written with owner-only permissions |
| `create_` | Written only if the file does not exist yet |
| `.tmpl` | Processed as template (variables, secrets) |
| `run_once_` | Runs once per machine, and again when the script changes |
| `run_onchange_` | Runs whenever the rendered script changes |
| `after_NN-` | Runs after the files are written, in numeric order |

## CI

Every push and pull request applies the repo into a scratch home on a macOS runner, once per machine type. It checks that templates render, scripts pass `shellcheck`, the Brewfiles load, and no repo file leaks into `$HOME`. It does not install packages.

## License

[MIT](LICENSE)

## Author

[Ignacio Velazquez](http://ignaciovelazquez.es)
