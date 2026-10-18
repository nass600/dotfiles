# --- step helpers ---
# Every step is best effort: an item that fails is printed with its reason, recorded in FAIL_FILE
# for the summary at the end of the apply, and retried on the next apply. Nothing stops the run
# except Ctrl-C. When an item needs something another step provides, its hint says so.
# Expects STEP, LOG, FAIL_FILE, NOTE_FILE, the C_* colours and fd 3 from log.sh.
#
#   step_total N                 how many items this step will attempt (for the [n/N] counter)
#   item_begin NAME              start a progress line
#   item_ok                      finish it as ok, with the elapsed time
#   item_fail REASON HINT        finish it as FAIL: prints REASON, records both for the summary
#   run_item NAME HINT CMD...    item_begin + run CMD (output to the log) + item_ok or item_fail
#   step_done LABEL              closing line for the step
#   note_manual TEXT             something only a human can do, printed again by the summary
STEP_N=0
STEP_TOTAL=0
STEP_FAILED=0
STEP_ITEM=""
STEP_START=0

step_total() {
    STEP_TOTAL=$1
    STEP_N=0
    STEP_FAILED=0
}

item_begin() {
    STEP_N=$((STEP_N + 1))
    STEP_ITEM="$1"
    STEP_START=$(date +%s)
    printf '  %s[%2d/%d]%s %-34s ' "$C_DIM" "$STEP_N" "$STEP_TOTAL" "$C_OFF" "$1"
}

item_ok() {
    printf '%sok%s    %s%4ss%s\n' "$C_GREEN" "$C_OFF" "$C_DIM" "$(( $(date +%s) - STEP_START ))" "$C_OFF"
}

item_fail() {
    local reason="${1:-}" hint="${2:-}"
    printf '%sFAIL%s  %s%4ss%s\n' "$C_RED" "$C_OFF" "$C_DIM" "$(( $(date +%s) - STEP_START ))" "$C_OFF"
    if [ -n "$reason" ]; then
        printf '           %s%s%s\n' "$C_DIM" "$(printf '%s' "$reason" | cut -c1-160)" "$C_OFF"
    fi
    printf '%s\t%s\t%s\t%s\n' "$STEP" "$STEP_ITEM" "$reason" "$hint" >>"$FAIL_FILE"
    STEP_FAILED=$((STEP_FAILED + 1))
}

note_manual() {
    printf '%s●%s %s\n' "$C_YELLOW" "$C_OFF" "$1"
    printf '%s\t%s\n' "$STEP" "$1" >>"$NOTE_FILE"
}

# The most telling line of a command's output, for the FAIL line: an Error line if there is one,
# otherwise the first line.
first_error() {
    { grep -m1 -E '^Error:|^error:|^ERROR:| Error:|rror: ' "$1" || grep -m1 . "$1"; } 2>/dev/null | head -1 || true
}

run_item() {
    local name="$1" hint="$2" out rc=0
    shift 2
    item_begin "$name"
    out="$(mktemp)"
    "$@" >"$out" 2>&1 || rc=$?
    cat "$out" >&3
    if [ "$rc" = 0 ]; then
        item_ok
    elif [ "$rc" = 130 ]; then
        printf '%sinterrupted%s\n' "$C_YELLOW" "$C_OFF"
        rm -f "$out"
        echo ""
        echo "Stopped by Ctrl-C. Run \`chezmoi apply\` to resume: what is already in place is skipped."
        exit 130
    else
        item_fail "$(first_error "$out")" "$hint"
    fi
    rm -f "$out"
}

step_done() {
    local label="$1"
    if [ "$STEP_TOTAL" = 0 ]; then
        echo "$label: nothing to do."
    elif [ "$STEP_FAILED" = 0 ]; then
        printf '%s: %s%s done.%s\n' "$label" "$C_GREEN" "$STEP_TOTAL" "$C_OFF"
    else
        printf '%s: %s%s of %s done%s, %s%s failed%s %s(listed at the end; full output in %s)%s\n' \
            "$label" "$C_GREEN" "$((STEP_TOTAL - STEP_FAILED))" "$STEP_TOTAL" "$C_OFF" \
            "$C_RED" "$STEP_FAILED" "$C_OFF" "$C_DIM" "$LOG" "$C_OFF"
    fi
}
