# dotfiles

[![macos](https://img.shields.io/badge/macos_27-white?style=for-the-badge&logo=apple&logoColor=black)]()
[![chezmoi](https://img.shields.io/badge/managed_with-chezmoi-blue?style=for-the-badge)](https://www.chezmoi.io)
[![GitHub tag](https://img.shields.io/github/tag/nass600/dotfiles.svg?style=for-the-badge&logo=github)]()

My macOS setup. **One command** takes a fresh MacBook to fully configured: dotfiles, apps, macOS settings, runtimes, editor extensions and secrets. Which Mac it is comes from 1Password: the setup asks one question, which vault, and reads everything about the machine from a `dotfiles` note in it (see [Machines and vaults](#-machines-and-vaults)).

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
3. **Which 1Password vault**: picked from the vaults 1Password lists by typing its first letters, in lowercase. Its `dotfiles` note says who this Mac is: git email, app bundle, prompt colour, backups. Touch ID once right after, while the note is read
4. **Dotfiles and packages**: one line per item, `[12/30] ffmpeg … ok 41s`, in this order: macOS defaults, command-line tools, apps, runtimes (mise), Cursor extensions, Lattice
5. **App Store apps**: installed only if the App Store is signed in, otherwise listed as pending. Never blocks the rest. `mas` asks for your password when run outside the installer
6. **GitHub CLI**, optional: sign in through the browser. Only the `gh` command needs it (releases, pull requests, CI). Git itself reaches GitHub over ssh through the 1Password agent, and https remotes are rewritten to ssh

> [!TIP]
> **Nothing stops the run.** Every step checks what is missing, installs only that, and carries on past failures; the last step prints one list of everything that could not be done, each with its reason and the fix. `chezmoi apply` retries exactly those. Ctrl-C is safe for the same reason. Every step also writes its full output to `~/Library/Logs/dotfiles/<step>.log`.

> [!NOTE]
> A package that fails **within seconds** with a connection error means its download host is unreachable from the current network, not a broken setup. Spanish ISPs black-hole some Cloudflare address ranges during LaLiga matches, which is enough to take out a vendor's download server for an evening. The installer gives up on such a host after about 30 seconds, reports it, and carries on; run `chezmoi apply` later.

<details>
<summary>Other ways to run it</summary>

```sh
# Check a Mac without changing anything
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh)" -- --check

# Try a branch
DOTFILES_BRANCH=my-branch sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/my-branch/install.sh)"
```

</details>

### ✋ Left to do by hand

The run ends with this list, rendered from `home/.chezmoidata/manual.toml` plus notes the steps add (Lattice asks for its Accessibility permission only when it was just built). macOS does not let a script do any of it.

- [ ] Open a new terminal, then log out and back in once: scroll direction, Finder and Dock settings only apply at login
- [ ] App Store apps still pending: sign in to the App Store, then `chezmoi apply`
- [ ] `gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow` the first time you need `gh`, if you skipped it
- [ ] Grant permissions as apps ask: Raycast, BetterSnapTool, iStat Menus, Logi Options+, Docker Desktop, Lattice (*Accessibility*)
- [ ] Create your desktops in Mission Control and turn on *Accessibility → Display → Reduce motion*
- [ ] Restore what this public repo leaves out: AWS credentials (`~/.aws`) and, on the personal Mac, the JDownloader backup from iCloud Drive `Config/jDownloader/`. Claude Code memory restores itself from iCloud Drive `Config/Claude/` (see below)
- [ ] Apps Homebrew no longer ships because they are unsigned: [Aegisub](https://github.com/TypesettingTools/Aegisub/releases), [MakeMKV](https://www.makemkv.com/download/), [rar](https://www.rarlab.com/download.htm). Download if needed and allow them once under *Privacy & Security*. Extracting rar archives works without them (`unar`, The Unarchiver)

> [!NOTE]
> Back those two up **before** wiping a Mac. JDownloader: *Settings → Backup → Create backup*. Claude Code memory (`~/.claude/projects`) is backed up daily to iCloud Drive `Config/Claude/` by `claude-backup`, run from a launch agent; run `claude-backup` once by hand right before the wipe, and the first `chezmoi apply` on the new Mac restores the newest archive for that hostname (four are kept per Mac).

## 🛠 Day to day

The repo lives at `~/Workspace/nass600/jarvis/dotfiles`, inside the [jarvis](https://github.com/nass600/jarvis) group repo, and that clone is chezmoi's source directory.

```sh
chezmoi cd                      # the home/ folder of this repo
chezmoi edit ~/.zshrc           # edit a managed file
chezmoi diff                    # preview
chezmoi apply                   # write files; installs whatever is missing from the Brewfiles / runtimes.toml
mise upgrade                    # newer node/python/tool versions, when you decide
brewdrift                       # installed but not in any Brewfile
brew bundle check --verbose --file=packages/Brewfile   # in a Brewfile but not installed (from the repo root)
```

| To change | Edit |
|---|---|
| 📦 Apps | `packages/Brewfile` (every Mac), `Brewfile.personal` or `Brewfile.work` (the bundle named by `apps` in the vault's `dotfiles` note) |
| 🧰 Node, Python, npm and PyPI tools (via mise), Cursor extensions, apps built from source | `home/.chezmoidata/runtimes.toml` |
| 🏠 ssh hosts, shell extras, git email, prompt colour | The `dotfiles` secure note in the vault (fields below). Pasted into `~/.ssh/config`, `~/.zshrc.local`, `~/.gitconfig`, `~/.p10k.zsh.local` |
| 🔐 GitHub access | ssh only, via the 1Password agent; `~/.gitconfig` rewrites https GitHub remotes to ssh |
| 💻 Which vault this Mac belongs to | `chezmoi init --prompt` |

> [!IMPORTANT]
> If it is not in a file here, it is not part of the setup. Secrets, hosts, addresses, emails and employer names never are: they are read from 1Password when `chezmoi init` and `chezmoi apply` run.

## 🔐 Machines and vaults

The repo is public and says nothing about where I work or what my networks look like. Each context, personal or an employer, is a **1Password vault** holding a secure note called **`dotfiles`** with the same fields everywhere. At `chezmoi init` the only question is which vault this Mac belongs to, picked from the vaults 1Password lists: `Private` for a personal Mac, the employer's vault for a work one. Everything below comes from that vault's note.

| Field | Value | What it drives |
|---|---|---|
| `profile` | one word, e.g. `personal` | the context's name, kept in `chezmoi data` |
| `email` | address | `[user] email` in `~/.gitconfig` |
| `apps` | `personal` or `work` | which `packages/Brewfile.<apps>`, `[runtimes.<apps>]` and `[manual.<apps>]` apply on top of the shared ones. Bundles are generic; a company never gets its own |
| `claude_backup` | `true` / `false` | whether the Claude Code memory backup agent and its steps render |
| `prompt_color` | 256-colour index | `P10K_COLOR_PRIMARY`, the accent that tells the Macs apart |
| `ssh_config` | OpenSSH `Host` blocks, no `IdentityFile` | appended to `~/.ssh/config` |
| `zshrc` | zsh exports and aliases | appended to `~/.zshrc.local` |

SSH keys are **SSH Key** items in the same vault; `~/.config/1Password/ssh/agent.toml` names the chosen vault so the agent serves them. Every field exists in every note, empty allowed. A work Mac that should also reach home hosts gets them in the employer note's `ssh_config`. A new employer is a new vault with a `dotfiles` note and its keys, then `chezmoi init` picking that vault: no change to this repo.

CI has no 1Password, so it renders both bundles from `DOTFILES_*` environment variables instead of a note. A repository secret, `FORBIDDEN_PATTERNS`, lists the words that must never appear here (one regex per line), and the build fails if any does.

## 🗂 Layout

```
dotfiles
├── install.sh                                    bootstrap for a fresh Mac (also --check)
├── packages/
│   ├── Brewfile                                  apps and CLI tools, every Mac
│   ├── Brewfile.personal
│   └── Brewfile.work
├── .chezmoiroot                                  tells chezmoi the dotfiles live in home/
└── home/                                         mirrors $HOME
    ├── .chezmoi.toml.tmpl                        init prompt: which vault, from `op vault list`; identity from its note; Homebrew env
    ├── .chezmoidata/runtimes.toml                node, python, npm/PyPI tools, extensions, source builds
    ├── .chezmoidata/manual.toml                  the "left to do by hand" list, per app bundle
    ├── .chezmoitemplates/
    │   ├── log.sh                                logging header shared by the scripts
    │   ├── step.sh                               [n/N] progress lines, failure list, shared by every step
    │   └── brew-step.sh                          per-package Homebrew install on top of step.sh
    ├── .chezmoiscripts/                          every step checks, installs what is missing, never stops the apply
    │   ├── run_before_00-begin.sh.tmpl           empties the failure list
    │   ├── run_once_after_10-macos-defaults.sh.tmpl
    │   ├── run_after_11-power.sh.tmpl            sleep timers: display 20 min, Mac 1 h on battery, 2 h on the adapter (sudo)
    │   ├── run_after_20-brew-formulae.sh.tmpl    taps + CLI tools
    │   ├── run_after_21-brew-casks.sh.tmpl       apps and fonts
    │   ├── run_after_30-runtimes.sh.tmpl         mise install + the private uv tools
    │   ├── run_after_35-cursor-extensions.sh.tmpl
    │   ├── run_after_40-lattice.sh.tmpl          built from source when the version changes
    │   ├── run_after_50-launch-agents.sh.tmpl    loads ~/Library/LaunchAgents when a plist changes
    │   ├── run_after_60-claude-memory.sh.tmpl    restores Claude Code memory from iCloud on an empty Mac
    │   ├── run_after_90-mas.sh.tmpl              App Store apps
    │   └── run_after_99-summary.sh.tmpl          what could not be done, then what only you can do
    ├── dot_zshrc · dot_zprofile · dot_p10k.zsh*  shell and prompt (+ dot_zshrc.local.tmpl from the vault's note)
    ├── dot_gitconfig.tmpl · dot_gitignore        git
    ├── dot_config/                               ghostty, micro, lattice, homebrew (curl timeout), mise (from runtimes.toml), 1Password ssh agent vault
    ├── dot_local/bin/claude-backup               Claude Code memory to iCloud Drive, and back
    ├── private_dot_ssh/                          ssh config (hosts from the vault's note) and router public key, both from 1Password
    ├── private_dot_npmrc.tmpl                    npm token from 1Password
    ├── private_dot_claude/                       Claude Code global instructions, settings and skills
    └── private_Library/                          Cursor and MKVToolNix settings, the claude-backup launch agent (claude_backup = true)
```

Files use chezmoi's [naming](https://www.chezmoi.io/reference/source-state-attributes/): `dot_` → `.`, `private_` → owner-only, `.tmpl` → templated, `create_` → seeded once and then left to the app (Claude, Cursor, MKVToolNix rewrite their own settings). Scripts: `run_once_` runs once per machine, `run_` on every apply.

Three tools own the state: chezmoi for files and secrets, Homebrew for packages and apps, [mise](https://mise.jdx.dev) for node, python and their global tools (`~/.config/mise/config.toml` is rendered from `runtimes.toml`). The scripts only cover what none of them does: sleep timers, Cursor extensions, Lattice, launch agents, Claude Code memory, App Store sign-in, and the two private PyPI tools that mise cannot see.

Every step follows the same contract: find out what is missing (a few seconds when nothing is), install only that one item at a time with a `[n/N] name … ok 41s` line each, and record what failed instead of stopping. An item that needs another step's work, say a `uv` tool when the `uv` formula is absent, fails with a hint pointing at that step. The last step prints the whole list; `chezmoi apply` retries only what is still missing. Only Ctrl-C ends a run early.

CI applies the repo into a scratch home for each app bundle and checks that templates render, scripts pass shellcheck, nothing leaks from the repo into `$HOME` and no forbidden pattern is committed. It does not install packages.

## 📄 License

[MIT](LICENSE) · [Ignacio Velazquez](http://ignaciovelazquez.es)
