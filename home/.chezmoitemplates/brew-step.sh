# --- Homebrew step helpers (need step.sh) ---
# Expects BREWFILES (array of Brewfile paths).
#
#   brew_plan FILE KIND...       copy the Brewfile lines of the given kinds (tap, brew, cask, mas) to FILE
#   brew_update_once             one visible `brew update`; scripts otherwise never auto-update
#   brew_install_plan FILE LABEL install what `brew bundle check` reports missing, one entry at a time
#
# Each entry runs as its own one-line `brew bundle`, so Brewfile syntax keeps working (tap-qualified
# names, `link: true`, cask args, `--adopt` for apps already in /Applications), progress shows per
# package, and one failing entry never blocks the rest.

if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# Homebrew breaks on every command when HOMEBREW_CURLRC names a missing file.
if [ -n "${HOMEBREW_CURLRC:-}" ] && [ ! -f "$HOMEBREW_CURLRC" ]; then
    unset HOMEBREW_CURLRC
fi

brew_plan() {
    local out="$1" kinds
    shift
    kinds="$(IFS='|'; echo "$*")"
    grep -hE "^($kinds) " "${BREWFILES[@]}" >"$out" || true
}

brew_update_once() {
    local start
    printf 'Updating Homebrew... '
    start=$(date +%s)
    if brew update --quiet >&3 2>&1; then
        printf '%sdone (%ss)%s\n' "$C_DIM" "$(( $(date +%s) - start ))" "$C_OFF"
    else
        printf 'failed after %ss, continuing with the cached index (details in %s)\n' "$(( $(date +%s) - start ))" "$LOG"
    fi
}

# Writes the names `brew bundle check` reports as missing for a plan to $2, one per line.
# Returns 1 when the check itself failed (Homebrew error, no network for the index), because
# an empty list must never be mistaken for "all installed".
BREW_CHECK_ERROR=""
brew_missing() {
    local plan="$1" list="$2" report rc=0
    report="$(brew bundle check --verbose --no-upgrade --file="$plan" 2>&1)" || rc=$?
    sed -nE 's/^→ (Formula|Cask|App|Tap) (.+) needs to be (installed|tapped)\.$/\2/p' <<<"$report" >"$list"
    if [ "$rc" != 0 ] && ! [ -s "$list" ]; then
        printf '%s\n' "$report" >&3
        BREW_CHECK_ERROR="$(printf '%s\n' "$report" | grep -m1 -E '^Error:|rror' || printf '%s\n' "$report" | tail -1)"
        return 1
    fi
}

brew_bundle_line() {
    printf '%s\n' "$1" | brew bundle --no-upgrade --file=-
}

brew_install_plan() {
    local plan="$1" label="$2"
    local total missing n name line hint
    total=$(grep -c . "$plan" || true)
    [ "$total" = 0 ] && return 0

    missing="$(mktemp)"
    if ! brew_missing "$plan" "$missing"; then
        echo "Homebrew $label: could not check what is missing."
        step_total 1
        item_begin "(brew bundle check)"
        item_fail "$BREW_CHECK_ERROR" "Homebrew itself is unhappy: brew doctor, then chezmoi apply"
        rm -f "$missing"
        return 0
    fi
    n=$(grep -c . "$missing" || true)
    if [ "$n" = 0 ]; then
        echo "Homebrew $label: all $total in place."
        rm -f "$missing"
        return 0
    fi
    echo "Homebrew $label: $total listed, $n to install."

    step_total "$n"
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        line="$(grep -F -m1 "\"$name\"" "$plan" || true)"
        case "$line" in
            cask\ *) hint="brew install --cask $name; a download that fails in seconds means its host is unreachable right now, try later" ;;
            tap\ *)  hint="brew tap $name" ;;
            *)       hint="brew install $name; a download that fails in seconds means its host is unreachable right now, try later" ;;
        esac
        run_item "$name" "$hint" brew_bundle_line "$line"
    done <"$missing"
    rm -f "$missing"
    step_done "Homebrew $label"
}
