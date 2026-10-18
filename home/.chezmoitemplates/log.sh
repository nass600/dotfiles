# --- logging ---
# Everything this script prints also goes to ~/Library/Logs/dotfiles/<step>.log (one dated block per
# run), so a failed `chezmoi apply` can be read back later. Prompts still work: stdin is untouched.
LOG_DIR="$HOME/Library/Logs/dotfiles"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/{{ . }}.log"
printf '\n=== %s  %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$0" >>"$LOG"
exec 3>>"$LOG"
exec > >(tee -a "$LOG") 2>&1
