#!/bin/sh
# macOS system settings. chezmoi runs this once per machine, and again whenever this file changes.
#
# Verified on macOS 15.7.4 (Sequoia), 2026-10-03: every key below was read back from a machine
# that has been running these values. Apple moves keys between releases, so re-verify after a
# major upgrade with `defaults read <domain> <key>` and drop anything that no longer sticks.
#
# Removed because they no longer work:
#   com.apple.menuextra.clock DateFormat   -> replaced by the Show* keys below
#   com.apple.loginwindow GuestEnabled     -> needs sudo on /Library/Preferences; guest is off by default

echo "Applying macOS defaults..."

# --- Interface ---
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# --- Dock ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -integer 30
defaults write com.apple.dock show-recents -bool false

# --- Trackpad ---
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5

# --- Menu bar clock: weekday, 24-hour, date when space allows ---
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock Show24Hour -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0

# --- Finder ---
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"       # search the current folder
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder NewWindowTarget -string "PfHm"            # new windows open Home
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"       # list view
defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"

# --- Desktop Services ---
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# --- Mission Control ---
# Keep desktops in a fixed order; Lattice maps them onto a grid by position.
defaults write com.apple.dock mru-spaces -bool false

# --- Workspace ---
mkdir -p "$HOME/Workspace/nass600"

# Restart the apps that cache these settings.
for app in Dock Finder SystemUIServer; do
    killall "$app" >/dev/null 2>&1 || true
done

echo "macOS defaults applied. Some settings need a logout to take effect."
