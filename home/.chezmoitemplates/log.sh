# --- logging ---
# Everything this script prints also goes to ~/Library/Logs/dotfiles/<step>.log (one dated block per
# run), so a failed `chezmoi apply` can be read back later. Prompts still work: stdin is untouched.
# fd 3 writes to the log only: use it for verbose tool output that would drown the terminal.
# FAIL_FILE collects this apply's failures for the summary step (99-summary).
STEP="{{ . }}"
LOG_DIR="$HOME/Library/Logs/dotfiles"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$STEP.log"
# shellcheck disable=SC2034 # used by the steps that include step.sh
FAIL_FILE="$LOG_DIR/failures.tsv"
printf '\n=== %s  %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$0" >>"$LOG"
exec 3>>"$LOG"
exec > >(tee -a "$LOG") 2>&1
printf '\n==> %s\n' "$STEP"
