# dotfiles

[![macos](<https://img.shields.io/badge/macos_15_(sequoia)-white?style=for-the-badge&logo=apple&logoColor=black>)]()
[![chezmoi](https://img.shields.io/badge/managed_with-chezmoi-blue?style=for-the-badge)](https://www.chezmoi.io)
[![GitHub tag](https://img.shields.io/github/tag/nass600/dotfiles.svg?style=for-the-badge&logo=github)]()

My macOS setup. **One command** takes a fresh MacBook to fully configured: dotfiles, apps, macOS settings, runtimes, editor extensions and secrets, for either of my two machines (`personal` / `work`).

## 🚀 Fresh install

Open Terminal on the new Mac and run:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh)"
```

> [!WARNING]
> Use this exact form. `curl … | sh` detaches the terminal and Homebrew refuses to install.

Nothing needs installing first. Have these ready:

| 🔑 | Used for |
|---|---|
| **macOS password** | Asked once, at the start |
| **1Password sign-in** | Secrets and ssh keys. Emergency Kit, or another signed-in device |
| **Apple ID** | App Store apps. Sign in during the setup assistant and this pause disappears |

The run takes 30 to 60 minutes and stops only here, each time with instructions on screen:

1. Password
2. 1Password: sign in, then enable **Integrate with 1Password CLI** and **Use the SSH agent** under *Settings → Developer*
3. Which machine this is: `personal` or `work`
4. App Store sign-in, if skipped earlier
5. Touch ID for the ssh key, when the private tools are installed
6. GitHub CLI sign-in in the browser

> [!TIP]
> Every step also writes its output to `~/Library/Logs/dotfiles/`. If one fails, fix the cause and run `chezmoi apply`: it continues from where it stopped.

<details>
<summary>Other ways to run it</summary>

```sh
# Check a machine without changing anything
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh)" -- --check

# Try a branch
DOTFILES_BRANCH=my-branch sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/my-branch/install.sh)"
```

</details>

### ✋ Left to do by hand

The script prints this list at the end. macOS does not let a script do any of it.

- [ ] Open a new terminal, then log out and back in once
- [ ] Grant permissions as apps ask: Raycast, BetterSnapTool, iStat Menus, Logi Options+, Docker Desktop, Lattice (*Accessibility*)
- [ ] Create your desktops in Mission Control and turn on *Accessibility → Display → Reduce motion*
- [ ] Restore what this public repo leaves out: Claude Code memory (`~/.claude/projects`), AWS credentials (`~/.aws`) and, on the personal Mac, the JDownloader backup from iCloud Drive `Config/jDownloader/`

> [!NOTE]
> Back those three up **before** wiping a Mac. JDownloader: *Settings → Backup → Create backup*.

## 🛠 Day to day

```sh
chezmoi cd                      # the home/ folder of this repo
chezmoi edit ~/.zshrc           # edit a managed file
chezmoi diff                    # preview
chezmoi apply                   # write files; re-runs brew bundle / runtimes / builds when their inputs changed
brewdrift                       # installed but not in any Brewfile
brew bundle check --verbose --file=packages/Brewfile   # in a Brewfile but not installed (from the repo root)
```

| To change | Edit |
|---|---|
| 📦 Apps | `packages/Brewfile` (both machines), `Brewfile.personal` or `Brewfile.work` |
| 🧰 Runtimes, global tools, Cursor extensions, prompt colour, apps built from source | `home/.chezmoidata/runtimes.toml` |
| 🏠 Home network ssh hosts | The **Home network** secure note in 1Password. Its text is pasted into `~/.ssh/config` |
| 💻 Which machine this is | `chezmoi init --prompt` |

> [!IMPORTANT]
> If it is not in a file here, it is not part of the setup. Secrets and network details never are: they are read from 1Password when `chezmoi apply` runs.

## 🗂 Layout

```
dotfiles
├── install.sh                                    bootstrap for a fresh Mac (also --check)
├── packages/
│   ├── Brewfile                                  apps and CLI tools, both machines
│   ├── Brewfile.personal
│   └── Brewfile.work
├── .chezmoiroot                                  tells chezmoi the dotfiles live in home/
└── home/                                         mirrors $HOME
    ├── .chezmoi.toml.tmpl                        init prompt: which machine
    ├── .chezmoidata/runtimes.toml                node, python, uv/pipx tools, extensions, prompt colours, source builds
    ├── .chezmoitemplates/log.sh                  logging header shared by the scripts
    ├── .chezmoiscripts/
    │   ├── run_once_after_10-macos-defaults.sh.tmpl
    │   ├── run_onchange_after_20-brew-bundle.sh.tmpl
    │   ├── run_onchange_after_30-runtimes.sh.tmpl
    │   └── run_onchange_after_40-lattice.sh.tmpl
    ├── dot_zshrc · dot_zprofile · dot_p10k.zsh*  shell and prompt
    ├── dot_gitconfig.tmpl · dot_gitignore        git
    ├── dot_config/                               ghostty, micro, lattice
    ├── private_dot_ssh/                          ssh config and router public key, both from 1Password
    ├── private_dot_npmrc.tmpl                    npm token from 1Password
    ├── private_dot_claude/                       Claude Code global instructions and settings
    └── private_Library/                          Cursor and MKVToolNix settings
```

Files use chezmoi's [naming](https://www.chezmoi.io/reference/source-state-attributes/): `dot_` → `.`, `private_` → owner-only, `.tmpl` → templated, `create_` → seeded once and then left to the app (Claude, Cursor, MKVToolNix rewrite their own settings).

CI applies the repo into a scratch home for each machine type and checks that templates render, scripts pass shellcheck and nothing leaks from the repo into `$HOME`. It does not install packages.

## 📄 License

[MIT](LICENSE) · [Ignacio Velazquez](http://ignaciovelazquez.es)
