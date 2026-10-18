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
OP_NETWORK_ITEM="op://Private/Home network/notesPlain"
OP_SSH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
LOG_DIR="$HOME/Library/Logs/dotfiles"

MODE="install"
for arg in "$@"; do
    case "$arg" in
        --check) MODE="check" ;;
        --) ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------- helpers

# Colours only on a terminal and never with NO_COLOR: cyan = where you are, green = done,
# red = failed, yellow = needs you, dim = detail. The chezmoi steps use the same five.
if { [ -t 1 ] || [ -n "${CLICOLOR_FORCE:-}" ]; } && [ -z "${NO_COLOR:-}" ]; then
    C_CYAN="$(printf '\033[36m')" C_GREEN="$(printf '\033[32m')" C_RED="$(printf '\033[31m')"
    C_YELLOW="$(printf '\033[33m')" C_DIM="$(printf '\033[2m')" C_BOLD="$(printf '\033[1m')" C_OFF="$(printf '\033[0m')"
else
    C_CYAN="" C_GREEN="" C_RED="" C_YELLOW="" C_DIM="" C_BOLD="" C_OFF=""
fi

banner() {
    echo ""
    printf '%s----------------------------------------------------------------%s\n' "$C_DIM" "$C_OFF"
    printf '%s  %s%s\n' "$C_CYAN" "$1" "$C_OFF"
    printf '%s----------------------------------------------------------------%s\n' "$C_DIM" "$C_OFF"
}
# A line that needs the human.
needs_you() { printf '%s●%s %s\n' "$C_YELLOW" "$C_OFF" "$1"; }

load_brew() {
    if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# Homebrew tuning for this run. The same file is managed by chezmoi afterwards and the same
# variables are set for every run script through scriptEnv in the chezmoi config.
homebrew_env() {
    mkdir -p "$HOME/.config/homebrew"
    if [ ! -f "$HOME/.config/homebrew/curlrc" ]; then
        printf '%s\n' \
            "# curl options for Homebrew only (HOMEBREW_CURLRC points here; install.sh writes the same file" \
            "# before Homebrew exists). A download host that drops packets fails after 10 seconds instead of" \
            "# blocking an install for minutes. Transfers themselves have no time limit." \
            "connect-timeout = 10" > "$HOME/.config/homebrew/curlrc"
    fi
    HOMEBREW_CURLRC="$HOME/.config/homebrew/curlrc"; export HOMEBREW_CURLRC
    HOMEBREW_CURL_RETRIES=0; export HOMEBREW_CURL_RETRIES
    HOMEBREW_NO_ENV_HINTS=1; export HOMEBREW_NO_ENV_HINTS
}

# Reading a real item is the only reliable test: with the desktop-app integration `op whoami`
# reports "not signed in" until something asks for a secret. The *_why functions print the reason
# a check fails, so the wait below can show it instead of a bare "not yet".
op_token_ok()    { command -v op >/dev/null 2>&1 && op read "$OP_NPM_ITEM" >/dev/null 2>&1; }
op_token_why()   { command -v op >/dev/null 2>&1 || { echo "op is not installed"; return; }; op read "$OP_NPM_ITEM" 2>&1 >/dev/null | tail -1; }
op_network_ok()  { op read "$OP_NETWORK_ITEM" 2>/dev/null | grep -q "^Host "; }
op_network_why() {
    if out="$(op read "$OP_NETWORK_ITEM" 2>&1)"; then
        echo "the item exists but contains no ssh \"Host\" lines"
    else
        echo "$out" | tail -1
    fi
}
ssh_agent_ok()   { [ -S "$OP_SSH_SOCK" ] && SSH_AUTH_SOCK="$OP_SSH_SOCK" ssh-add -l >/dev/null 2>&1; }
ssh_agent_why() {
    [ -S "$OP_SSH_SOCK" ] || { echo "the agent socket does not exist yet (Use the SSH agent is off)"; return; }
    SSH_AUTH_SOCK="$OP_SSH_SOCK" ssh-add -l 2>&1 | tail -1
}
github_ssh_ok() {
    SSH_AUTH_SOCK="$OP_SSH_SOCK" ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new \
        -T git@github.com 2>&1 | grep -q "successfully authenticated"
}

# Repeat a check until it passes, retrying on its own every 5 seconds and printing the reason
# whenever it changes. $1 = check, $2 = what to do about it, $3 = reason function,
# $4 = "optional" lets you type `skip` + Enter to go on without it.
wait_until() {
    "$1" && return 0
    echo ""
    echo "$2"
    last=""
    if [ "${4:-}" = "optional" ]; then
        printf "  %sChecking every 5s. Type 'skip' + Enter to continue without it%s" "$C_DIM" "$C_OFF"
    else
        printf "  %sChecking every 5s. Ctrl-C stops the install; it resumes with \`chezmoi apply\`%s" "$C_DIM" "$C_OFF"
    fi
    while :; do
        why="$("$3" 2>/dev/null)"
        if [ -n "$why" ] && [ "$why" != "$last" ]; then
            printf "\n  -> %s\n  Waiting" "$why"
            last="$why"
        fi
        printf "."
        REPLY=""
        # shellcheck disable=SC3045 # macOS /bin/sh is bash; read -t exists there
        read -t 5 -r REPLY < /dev/tty || true
        if [ "$REPLY" = "skip" ] && [ "${4:-}" = "optional" ]; then
            echo ""
            return 1
        fi
        if "$1"; then
            printf ' %sok%s\n' "$C_GREEN" "$C_OFF"
            return 0
        fi
    done
}

# ---------------------------------------------------------------- --check

run_check() {
    load_brew
    fails=0
    row() {
        if [ "$2" = ok ]; then printf '  %sok%s    %s\n' "$C_GREEN" "$C_OFF" "$1"
        else printf '  %sFAIL%s  %s%s\n' "$C_RED" "$C_OFF" "$1" "${3:+  ${C_YELLOW}->  $3${C_OFF}}"; fails=$((fails + 1)); fi
    }
    is() { if "$@" >/dev/null 2>&1; then echo ok; else echo fail; fi; }

    echo "Readiness report for $(scutil --get ComputerName 2>/dev/null || hostname) (macOS $(sw_vers -productVersion), $(uname -m))"
    echo ""
    row "Apple Silicon"                      "$(is test "$(uname -m)" = arm64)"       "this setup assumes /opt/homebrew"
    row "Xcode Command Line Tools"           "$(is xcode-select -p)"                  "installed automatically with Homebrew"
    row "Homebrew"                           "$(is command -v brew)"                  "installed by this script"
    row "chezmoi"                            "$(is command -v chezmoi)"               "installed by this script"
    row "1Password app"                      "$(is test -d /Applications/1Password.app)" "installed by this script"
    row "1Password CLI can read secrets"     "$(is op_token_ok)"                      "Settings > Developer > Integrate with 1Password CLI; item $OP_NPM_ITEM"
    row "Home network item in 1Password"     "$(is op_network_ok)"                    "Private vault secure note \"Home network\" holding the ssh Host blocks"
    row "1Password SSH agent has keys"       "$(is ssh_agent_ok)"                     "1Password > Settings > Developer > Use the SSH agent"
    row "GitHub reachable over SSH"          "$(is github_ssh_ok)"                    "needed for the private doubtfire and parker installs"
    row "GitHub CLI signed in"               "$(is gh auth status)"                   "optional, for releases and PRs: gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow"
    if command -v chezmoi >/dev/null 2>&1 && [ -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
        pending="$(chezmoi status --exclude=scripts 2>/dev/null | wc -l | tr -d ' ')"
        row "Home directory matches the repo"  "$([ "$pending" = 0 ] && echo ok || echo fail)" "$pending pending change(s): run chezmoi diff"
        src="$(chezmoi source-path 2>/dev/null)/.."
        machine="$(chezmoi data --format=json 2>/dev/null | sed -nE 's/.*"machine": *"([a-z]+)".*/\1/p' | head -1)"
        if command -v brew >/dev/null 2>&1 && [ -f "$src/packages/Brewfile" ] && [ -n "$machine" ]; then
            # Exit 0 means satisfied. Anything else is either a list of missing entries or a
            # Homebrew error, and an error must not pass as "nothing missing".
            report="$(cat "$src/packages/Brewfile" "$src/packages/Brewfile.$machine" \
                | HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --no-upgrade --file=- 2>&1)" && brew_rc=0 || brew_rc=$?
            missing="$(printf '%s\n' "$report" | grep -c '→' || true)"
            if [ "$brew_rc" = 0 ]; then
                row "Homebrew packages and App Store apps" ok
            elif [ "$missing" != 0 ]; then
                row "Homebrew packages and App Store apps" fail "$missing missing: run chezmoi apply (App Store apps need a signed-in App Store)"
            else
                row "Homebrew packages and App Store apps" fail "could not check: $(printf '%s\n' "$report" | tail -1)"
            fi
        fi
    else
        row "chezmoi initialised"            fail                                     "run the installer"
    fi
    echo ""
    if [ "$fails" = 0 ]; then printf '%sEverything is in place.%s\n' "$C_GREEN" "$C_OFF"; else printf '%s%s item(s) need attention.%s\n' "$C_YELLOW" "$fails" "$C_OFF"; fi
    return "$fails"
}

if [ "$MODE" = "check" ]; then
    run_check
    exit $?
fi

# ---------------------------------------------------------------- install

printf '%sdotfiles install%s  fresh Mac to fully configured in one run\n' "$C_BOLD" "$C_OFF"
echo ""
echo "What happens, and what it needs from you:"
echo "  1. Administrator access      your macOS password, once"
echo "  2. 1Password                 sign in, enable the CLI integration and the SSH agent (skipped when already done)"
echo "  3. Which machine this is     personal or work"
echo "  4. Dotfiles and packages     command-line tools, apps, runtimes (mise), Cursor extensions, Lattice; one line per item"
echo "  5. App Store apps            only installs if the App Store is signed in; otherwise listed as pending"
echo "  6. GitHub CLI                optional: sign in for releases and pull requests (git itself uses the 1Password ssh key)"
echo ""
echo "Takes 30 to 60 minutes, most of it downloading. No single item can stop the run: whatever fails is"
echo "listed at the end with what to do about it, and \`chezmoi apply\` retries only that. Ctrl-C is safe"
echo "at any point for the same reason. Every step also logs to $LOG_DIR/"

# --- sudo, once ---
# Homebrew and a few app installers need it. Asking now and keeping it alive avoids
# password prompts appearing halfway through a long install.
banner "1/6  Administrator access"
sudo -v < /dev/tty
( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
KEEPALIVE_PID=$!
trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT

homebrew_env

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
banner "Installing prerequisite tools (chezmoi, gh, 1Password)"
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
# On a re-run they are usually already true: then nothing is asked (the check itself triggers
# the Touch ID prompt when 1Password wants one).
banner "2/6  1Password"
needs_you "Checking the 1Password CLI, the Home network item and the SSH agent."
needs_you "If 1Password asks for Touch ID or your password now, approve it: that is the check talking to the app."
if op_token_ok && op_network_ok && ssh_agent_ok; then
    printf '  %sok%s    Already set up. Nothing to do here.\n' "$C_GREEN" "$C_OFF"
else
    open -a "1Password" 2>/dev/null || true
    needs_you "1Password is open. This is the one step that needs you:"
    echo "  1. Sign in to 1Password"
    echo "  2. Settings -> Developer -> enable 'Integrate with 1Password CLI'"
    echo "  3. Settings -> Developer -> enable 'Use the SSH agent'"
    echo "  4. Approve the authorisation prompt (Touch ID or password) when it appears"
    echo "The install continues on its own as soon as each check passes."

    wait_until op_token_ok "Waiting for the 1Password CLI to read $OP_NPM_ITEM.
  Needs: 'Integrate with 1Password CLI' enabled, the authorisation prompt approved,
  and the item in the Personal vault with a field named 'credential'." op_token_why

    wait_until op_network_ok "Waiting for the \"Home network\" item in the Private vault.
  Needs: a secure note whose text is the ssh config Host blocks (gt500, router)." op_network_why

    wait_until ssh_agent_ok "Waiting for the 1Password SSH agent.
  Needs: 'Use the SSH agent' enabled. Without it the private tools (doubtfire, parker) cannot be installed." ssh_agent_why optional \
        || echo "Continuing without the SSH agent. Run \`chezmoi apply\` again once it is enabled."
fi

# --- Apply ---
# Asks which machine this is, then applies the dotfiles and runs the steps in order: macOS defaults,
# Homebrew formulae, casks, runtimes, Cursor extensions, Lattice, App Store apps, summary. Steps never
# stop the apply; the summary step lists what failed. chezmoi itself only exits non-zero on Ctrl-C or
# when a file cannot be written (a 1Password item missing, for instance).
banner "3/6  Which machine, then 4/6 dotfiles and packages, 5/6 App Store"
APPLY_RC=0
if [ -n "${DOTFILES_BRANCH:-}" ]; then
    chezmoi init --apply --branch "$DOTFILES_BRANCH" "$REPO" || APPLY_RC=$?
else
    chezmoi init --apply "$REPO" || APPLY_RC=$?
fi

# --- GitHub CLI (optional) ---
# Git never needs this: every GitHub remote goes over ssh through the 1Password agent. The `gh`
# command does, for releases, pull requests and CI. The workflow scope lets it push CI changes.
if [ "$APPLY_RC" != 130 ] && ! gh auth status >/dev/null 2>&1; then
    banner "6/6  GitHub CLI sign-in (optional)"
    needs_you "Only the gh command needs this (releases, pull requests, CI status). Git already works over ssh."
    printf "Sign in now through the browser? [y/N] "
    read -r REPLY < /dev/tty || REPLY=""
    case "$REPLY" in
        [Yy]*) gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web --scopes workflow < /dev/tty \
                   || echo "Not signed in. Later: gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow" ;;
        *)     echo "Skipped. Whenever you first need gh: gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow" ;;
    esac
fi

# --- Summary ---
banner "Summary"
run_check || true
echo ""
case "$APPLY_RC" in
    0)   echo "The apply finished. Anything it could not do is in the list above; \`chezmoi apply\` retries exactly that." ;;
    130) echo "The apply was interrupted. Run \`chezmoi apply\` to continue: what is already in place is skipped." ;;
    *)   echo "chezmoi stopped before the end (exit $APPLY_RC). The error above is usually a file it could not write,"
         echo "for example a 1Password item it could not read. Fix the cause and run: chezmoi apply" ;;
esac
echo ""
if [ -f "$LOG_DIR/manual.txt" ]; then
    printf '%s●%s %sLeft to do by hand%s\n' "$C_YELLOW" "$C_OFF" "$C_BOLD" "$C_OFF"
    [ "$APPLY_RC" = 0 ] || echo "  - run chezmoi apply first; this list is from the last apply that reached the end"
    if ! gh auth status >/dev/null 2>&1; then
        echo "  - gh not signed in: gh auth login --git-protocol ssh --skip-ssh-key --web -s workflow (releases, pull requests)"
    fi
    sed 's/^/  - /' "$LOG_DIR/manual.txt"
fi
