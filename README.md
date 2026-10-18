# dotfiles

[![macos](https://img.shields.io/badge/macos_27-white?style=for-the-badge&logo=apple&logoColor=black)]()
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
| **Apple ID** | App Store apps. Sign in during the setup assistant and nothing is asked later |

The run takes 30 to 60 minutes, most of it downloading, and prints what it is doing:

1. **Administrator access**: password, once
2. **1Password**: sign in, then enable **Integrate with 1Password CLI** and **Use the SSH agent** under *Settings → Developer*. The script re-checks every 5 seconds and moves on by itself; on a re-run where this already works, nothing is asked
3. **Which machine this is**: `personal` or `work`
4. **Dotfiles and packages**: one line per item, `[12/30] ffmpeg … ok 41s`, in this order: macOS defaults, command-line tools, apps, runtimes, Cursor extensions, Lattice
5. **App Store apps**: installed only if the App Store is signed in, otherwise listed as pending. Never blocks the rest. `mas` asks for your password when run outside the installer
6. **GitHub CLI**, optional: sign in through the browser. Only the `gh` command needs it (releases, pull requests, CI). Git itself reaches GitHub over ssh through the 1Password agent, and https remotes are rewritten to ssh

> [!TIP]
> **Nothing stops the run.** Every step checks what is missing, installs only that, and carries on past failures; the last step prints one list of everything that could not be done, each with its reason and the fix. `chezmoi apply` retries exactly those. Ctrl-C is safe for the same reason. Every step also writes its full output to `~/Library/Logs/dotfiles/<step>.log`.

> [!NOTE]
> A package that fails **within seconds** with a connection error means its download host is unreachable from the current network, not a broken setup. Spanish ISPs black-hole some Cloudflare address ranges during LaLiga matches, which is enough to take out a vendor's download server for an evening. The installer gives up on such a host after about 30 seconds, reports it, and carries on; run `chezmoi apply` later.

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
- [ ] App Store apps still pending: sign in to the App Store, then `chezmoi apply`
- [ ] `gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow` the first time you need `gh`, if you skipped it
- [ ] Grant permissions as apps ask: Raycast, BetterSnapTool, iStat Menus, Logi Options+, Docker Desktop, Lattice (*Accessibility*)
- [ ] Create your desktops in Mission Control and turn on *Accessibility → Display → Reduce motion*
- [ ] Restore what this public repo leaves out: Claude Code memory (`~/.claude/projects`), AWS credentials (`~/.aws`) and, on the personal Mac, the JDownloader backup from iCloud Drive `Config/jDownloader/`
- [ ] Apps Homebrew no longer ships because they are unsigned: [Aegisub](https://github.com/TypesettingTools/Aegisub/releases), [MakeMKV](https://www.makemkv.com/download/), [rar](https://www.rarlab.com/download.htm). Download if needed and allow them once under *Privacy & Security*. Extracting rar archives works without them (`unar`, The Unarchiver)

> [!NOTE]
> Back those three up **before** wiping a Mac. JDownloader: *Settings → Backup → Create backup*.

## 🛠 Day to day

```sh
chezmoi cd                      # the home/ folder of this repo
chezmoi edit ~/.zshrc           # edit a managed file
chezmoi diff                    # preview
chezmoi apply                   # write files; installs whatever is missing from the Brewfiles / runtimes
brewdrift                       # installed but not in any Brewfile
brew bundle check --verbose --file=packages/Brewfile   # in a Brewfile but not installed (from the repo root)
```

| To change | Edit |
|---|---|
| 📦 Apps | `packages/Brewfile` (both machines), `Brewfile.personal` or `Brewfile.work` |
| 🧰 Runtimes, global tools, Cursor extensions, prompt colour, apps built from source | `home/.chezmoidata/runtimes.toml` |
| 🏠 Home network ssh hosts | The **Home network** secure note in 1Password. Its text is pasted into `~/.ssh/config` |
| 🔐 GitHub access | ssh only, via the 1Password agent; `~/.gitconfig` rewrites https GitHub remotes to ssh |
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
    ├── .chezmoi.toml.tmpl                        init prompt: which machine; Homebrew env for the scripts
    ├── .chezmoidata/runtimes.toml                node, python, uv/pipx tools, extensions, prompt colours, source builds
    ├── .chezmoitemplates/
    │   ├── log.sh                                logging header shared by the scripts
    │   ├── step.sh                               [n/N] progress lines, failure list, shared by every step
    │   └── brew-step.sh                          per-package Homebrew install on top of step.sh
    ├── .chezmoiscripts/                          every step checks, installs what is missing, never stops the apply
    │   ├── run_before_00-begin.sh.tmpl           empties the failure list
    │   ├── run_once_after_10-macos-defaults.sh.tmpl
    │   ├── run_after_20-brew-formulae.sh.tmpl    taps + CLI tools
    │   ├── run_after_21-brew-casks.sh.tmpl       apps and fonts
    │   ├── run_after_30-runtimes.sh.tmpl         node, python, pipx and uv tools
    │   ├── run_after_35-cursor-extensions.sh.tmpl
    │   ├── run_after_40-lattice.sh.tmpl          built from source when the version changes
    │   ├── run_after_90-mas.sh.tmpl              App Store apps
    │   └── run_after_99-summary.sh.tmpl          the list of what could not be done
    ├── dot_zshrc · dot_zprofile · dot_p10k.zsh*  shell and prompt
    ├── dot_gitconfig.tmpl · dot_gitignore        git
    ├── dot_config/                               ghostty, micro, lattice, homebrew (curl timeout)
    ├── private_dot_ssh/                          ssh config and router public key, both from 1Password
    ├── private_dot_npmrc.tmpl                    npm token from 1Password
    ├── private_dot_claude/                       Claude Code global instructions and settings
    └── private_Library/                          Cursor and MKVToolNix settings
```

Files use chezmoi's [naming](https://www.chezmoi.io/reference/source-state-attributes/): `dot_` → `.`, `private_` → owner-only, `.tmpl` → templated, `create_` → seeded once and then left to the app (Claude, Cursor, MKVToolNix rewrite their own settings). Scripts: `run_once_` runs once per machine, `run_` on every apply.

Every step follows the same contract: find out what is missing (a few seconds when nothing is), install only that one item at a time with a `[n/N] name … ok 41s` line each, and record what failed instead of stopping. An item that needs another step's work, say a `uv` tool when the `uv` formula is absent, fails with a hint pointing at that step. The last step prints the whole list; `chezmoi apply` retries only what is still missing. Only Ctrl-C ends a run early.

CI applies the repo into a scratch home for each machine type and checks that templates render, scripts pass shellcheck and nothing leaks from the repo into `$HOME`. It does not install packages.

## 📄 License

[MIT](LICENSE) · [Ignacio Velazquez](http://ignaciovelazquez.es)
