#!/bin/sh
# Applies macOS system defaults.
# chezmoi runs this once on fresh install (run_once_ prefix).
# Verify each setting on macOS 15 Sequoia — Apple silently deprecates keys between releases.

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
# NOTE: Verify this key still works on macOS 15 — clock format keys have shifted in recent releases
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
