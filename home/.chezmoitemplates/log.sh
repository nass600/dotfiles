# --- logging and colour ---
# Everything this script prints also goes to ~/Library/Logs/dotfiles/<step>.log (one dated block per
# run, colour codes stripped), so a failed `chezmoi apply` can be read back later. Prompts still
# work: stdin is untouched. fd 3 writes to the log only: use it for verbose tool output.
# FAIL_FILE and NOTE_FILE collect this apply's failures and "do this by hand" notes for 99-summary.
# Colours (only on a terminal, and never with NO_COLOR set): cyan = where you are, green = done,
# red = failed, yellow = needs you, dim = counters, timings and paths.
STEP="{{ . }}"
LOG_DIR="$HOME/Library/Logs/dotfiles"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$STEP.log"
# shellcheck disable=SC2034 # used by the steps that include step.sh
FAIL_FILE="$LOG_DIR/failures.tsv"
# shellcheck disable=SC2034
NOTE_FILE="$LOG_DIR/manual.tsv"
# CLICOLOR_FORCE=1 turns colour on without a terminal (tests, CI logs you want coloured).
if { [ -t 1 ] || [ -n "${CLICOLOR_FORCE:-}" ]; } && [ -z "${NO_COLOR:-}" ]; then
    C_CYAN=$'\033[36m' C_GREEN=$'\033[32m' C_RED=$'\033[31m' C_YELLOW=$'\033[33m' C_DIM=$'\033[2m' C_BOLD=$'\033[1m' C_OFF=$'\033[0m'
else
    C_CYAN='' C_GREEN='' C_RED='' C_YELLOW='' C_DIM='' C_BOLD='' C_OFF=''
fi
# shellcheck disable=SC2034
export C_CYAN C_GREEN C_RED C_YELLOW C_DIM C_BOLD C_OFF
printf '\n=== %s  %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$0" >>"$LOG"
strip_colour() { sed -E $'s/\033\\[[0-9;]*m//g' >>"$LOG"; }
exec 3> >(strip_colour)
exec > >(tee >(strip_colour)) 2>&1
printf '\n%s==> %s%s\n' "$C_CYAN" "$STEP" "$C_OFF"
