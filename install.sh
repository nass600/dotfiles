#!/bin/sh
# One-command bootstrap for a fresh Mac:
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh)"
#
# Report readiness without changing anything:
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/main/install.sh)" -- --check
#
# Test a branch before merging it:
#
#   DOTFILES_BRANCH=my-branch sh -c "$(curl -fsSL https://raw.githubusercontent.com/nass600/dotfiles/my-branch/install.sh)"
set -e

REPO="nass600/dotfiles"
OP_NPM_ITEM="op://Personal/GH_NPM_REGISTRY/credential"
OP_SSH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

MODE="install"
for arg in "$@"; do
    case "$arg" in
        --check) MODE="check" ;;
        --) ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------- helpers

banner() {
    echo ""
    echo "----------------------------------------------------------------"
    echo "  $1"
    echo "----------------------------------------------------------------"
}

# Prompts read from /dev/tty so they work however the script was started.
ask() {
    printf "%s" "$1"
    read -r REPLY < /dev/tty || REPLY=""
}

load_brew() {
    if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# Reading a real item is the only reliable test: with the desktop-app integration `op whoami`
# reports "not signed in" until something asks for a secret.
op_token_ok()   { command -v op >/dev/null 2>&1 && op read "$OP_NPM_ITEM" >/dev/null 2>&1; }
ssh_agent_ok()  { [ -S "$OP_SSH_SOCK" ] && SSH_AUTH_SOCK="$OP_SSH_SOCK" ssh-add -l >/dev/null 2>&1; }
github_ssh_ok() {
    SSH_AUTH_SOCK="$OP_SSH_SOCK" ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new \
        -T git@github.com 2>&1 | grep -q "successfully authenticated"
}

# Repeat a check until it passes. $1 = check function, $2 = what to do about it, $3 = "optional" to allow skipping.
wait_until() {
    while ! "$1"; do
        echo ""
        echo "$2"
        if [ "${3:-}" = "optional" ]; then
            ask "Press Enter to check again, or type 'skip' to continue without it: "
            [ "$REPLY" = "skip" ] && return 1
        else
            ask "Press Enter to check again (Ctrl-C to stop): "
        fi
    done
    return 0
}

# ---------------------------------------------------------------- --check

run_check() {
    load_brew
    fails=0
    row() { if [ "$2" = ok ]; then echo "  ok    $1"; else echo "  FAIL  $1${3:+  ->  $3}"; fails=$((fails + 1)); fi; }
    is() { if "$@" >/dev/null 2>&1; then echo ok; else echo fail; fi; }

    echo "Readiness report for $(scutil --get ComputerName 2>/dev/null || hostname) (macOS $(sw_vers -productVersion), $(uname -m))"
    echo ""
    row "Apple Silicon"                      "$(is test "$(uname -m)" = arm64)"       "this setup assumes /opt/homebrew"
    row "Xcode Command Line Tools"           "$(is xcode-select -p)"                  "installed automatically with Homebrew"
    row "Homebrew"                           "$(is command -v brew)"                  "installed by this script"
    row "chezmoi"                            "$(is command -v chezmoi)"               "installed by this script"
    row "1Password app"                      "$(is test -d /Applications/1Password.app)" "installed by this script"
    row "1Password CLI can read secrets"     "$(is op_token_ok)"                      "Settings > Developer > Integrate with 1Password CLI; item $OP_NPM_ITEM"
    row "1Password SSH agent has keys"       "$(is ssh_agent_ok)"                     "1Password > Settings > Developer > Use the SSH agent"
    row "GitHub reachable over SSH"          "$(is github_ssh_ok)"                    "needed for the private doubtfire and parker installs"
    row "GitHub CLI signed in"               "$(is gh auth status)"                   "gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow"
    if command -v chezmoi >/dev/null 2>&1 && [ -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
        pending="$(chezmoi status 2>/dev/null | wc -l | tr -d ' ')"
        row "Home directory matches the repo"  "$([ "$pending" = 0 ] && echo ok || echo fail)" "$pending pending change(s): run chezmoi diff"
    else
        row "chezmoi initialised"            fail                                     "run the installer"
    fi
    echo ""
    if [ "$fails" = 0 ]; then echo "Everything is in place."; else echo "$fails item(s) need attention."; fi
    return "$fails"
}

if [ "$MODE" = "check" ]; then
    run_check
    exit $?
fi

# ---------------------------------------------------------------- install

echo "Starting dotfiles installation..."
echo ""
echo "Have these ready:"
echo "  - your macOS password (asked once)"
echo "  - your 1Password sign-in (Emergency Kit or another signed-in device)"
echo "  - your Apple ID, for the App Store"
echo "  - the NAS and router addresses and ssh ports"

# --- sudo, once ---
# Homebrew and a few app installers need it. Asking now and keeping it alive avoids
# password prompts appearing halfway through a long install.
banner "Administrator access"
sudo -v < /dev/tty
( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
KEEPALIVE_PID=$!
trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT

# --- Homebrew ---
# Its installer also installs the Xcode Command Line Tools headlessly when they are missing.
# stdin is pinned to the terminal: without one the installer demands passwordless sudo and aborts.
if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
    banner "Installing Homebrew (and the Xcode Command Line Tools)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
fi
load_brew

# --- Prerequisite tools ---
# chezmoi applies the dotfiles; 1Password supplies the secrets and ssh keys they depend on.
banner "Installing prerequisite tools"
brew install chezmoi gh
brew install --cask 1password 1password-cli || true
if [ ! -d /Applications/1Password.app ] || ! command -v op >/dev/null 2>&1; then
    echo ""
    echo "1Password could not be installed, and nothing else can proceed without it."
    echo "Check the Homebrew error above, then run this script again."
    exit 1
fi

# --- 1Password ---
# Two things must be true before applying, and each needs a click in the 1Password app.
banner "1Password"
open -a "1Password" 2>/dev/null || true

echo "1Password has been installed and opened. This is the one step that needs you:"
echo "  1. Sign in to 1Password"
echo "  2. Settings -> Developer -> enable 'Integrate with 1Password CLI'"
echo "  3. Settings -> Developer -> enable 'Use the SSH agent'"
echo "  4. Approve the authorisation prompt (Touch ID or password) when it appears"
ask "Press Enter when that is done... "

wait_until op_token_ok "The 1Password CLI cannot read $OP_NPM_ITEM yet.
  - Is 'Integrate with 1Password CLI' enabled under Settings -> Developer?
  - Did you approve the authorisation prompt?
  - Does the item exist in the Personal vault with a field named 'credential'?"

wait_until ssh_agent_ok "The 1Password SSH agent is not serving any keys.
  Settings -> Developer -> enable 'Use the SSH agent'
  Without it the private tools (doubtfire, parker) cannot be installed." optional \
    || echo "Continuing without the SSH agent. Run \`chezmoi apply\` again once it is enabled."

# --- Apply ---
# Asks which machine this is and for the home network hosts, then applies dotfiles, macOS defaults,
# Homebrew packages and language runtimes, in that order.
banner "Applying dotfiles"
APPLY_OK=1
if [ -n "${DOTFILES_BRANCH:-}" ]; then
    chezmoi init --apply --branch "$DOTFILES_BRANCH" "$REPO" || APPLY_OK=0
else
    chezmoi init --apply "$REPO" || APPLY_OK=0
fi

# --- GitHub CLI ---
# Backs the https credential helper in ~/.gitconfig. The workflow scope lets it push CI changes.
if ! gh auth status >/dev/null 2>&1; then
    banner "GitHub CLI sign-in"
    gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web --scopes workflow < /dev/tty \
        || echo "Skipped. Run it later: gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow"
fi

# --- Summary ---
banner "Summary"
run_check || true
echo ""
if [ "$APPLY_OK" = 1 ]; then
    echo "The apply finished."
else
    echo "The apply stopped early. Fix the error above and run: chezmoi apply"
fi
echo ""
echo "Left to do by hand:"
echo "  - open a new terminal so the new shell config loads"
echo "  - restore Claude Code memory into ~/.claude/projects (kept out of this public repo)"
echo "  - sign in to AWS: aws configure sso (or restore ~/.aws)"
echo "  - launch Docker Desktop once and accept its terms"
echo "  - grant app permissions as they ask (Raycast, BetterSnapTool, iStat Menus, Logi Options+)"
echo "  - log out and back in for the remaining macOS settings"
