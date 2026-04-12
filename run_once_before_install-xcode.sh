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
