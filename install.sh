#!/bin/sh
set -e

# Read from /dev/tty so prompts work even via `curl | sh`
prompt_enter() {
    printf "%s" "$1"
    read _ < /dev/tty
}

banner() {
    echo ""
    echo "----------------------------------------------------------------"
    echo "  $1"
    echo "----------------------------------------------------------------"
}

echo "Starting dotfiles installation..."

# --- Xcode Command Line Tools ---
if ! xcode-select -p >/dev/null 2>&1; then
    banner "Installing Xcode Command Line Tools"
    xcode-select --install
    echo "Complete the Xcode CLT installation dialog, then re-run this script."
    exit 0
fi

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
    banner "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Prerequisite tools ---
# Install these eagerly so chezmoi can use them during apply.
banner "Installing prerequisite tools"
brew install chezmoi mas
brew install --cask 1password 1password-cli || true

# --- Mac App Store sign-in ---
# `mas` cannot sign in programmatically (Apple removed the API in macOS 10.13).
# Open the App Store and wait for the user.
if ! mas account >/dev/null 2>&1; then
    banner "Mac App Store sign-in required"
    echo "The App Store app will open. Please sign in, then return here."
    open -a "App Store"
    prompt_enter "Press Enter once you're signed in to continue... "
fi

# --- 1Password sign-in ---
# `op` reads secrets into templated dotfiles (e.g. ~/.npmrc).
# The 1Password app must be installed, unlocked, and have CLI integration enabled
# (Settings → Developer → "Integrate with 1Password CLI").
if command -v op >/dev/null 2>&1; then
    if ! op whoami >/dev/null 2>&1; then
        banner "1Password sign-in required"
        echo "Some dotfiles pull secrets from 1Password (e.g. ~/.npmrc)."
        echo ""
        echo "  1. Open the 1Password app and sign in"
        echo "  2. Go to Settings → Developer"
        echo "  3. Enable 'Integrate with 1Password CLI'"
        echo ""
        open -a "1Password" || true
        prompt_enter "Press Enter once 1Password is unlocked and CLI is enabled... "
    fi
fi

# --- Apply dotfiles ---
banner "Applying dotfiles"
chezmoi init --apply nass600/dotfiles

echo ""
banner "Done"
echo "Open a new terminal session for all changes to take effect."
