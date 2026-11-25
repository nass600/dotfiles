#!/bin/zsh
# Keeps Claude's throwaway Ghostty windows from piling up.
#   pre  (PreToolUse/Bash): a command that launches Ghostty must tag it with --title=claude-<name>
#   stop (Stop/SessionEnd): quits every Ghostty process carrying that tag
# The user's own Ghostty runs with no --title=claude- argument, so it is never touched.

mode=$1

if [[ $mode == pre ]]; then
  cmd=$(jq -r '.tool_input.command // empty')
  # Launching Ghostty: `open ... Ghostty` or the ghostty binary itself, not mere mentions in grep/cat
  if print -r -- "$cmd" | grep -Eq '(^|[;&|[:space:]])open[[:space:]][^;&|]*[Gg]hostty|Ghostty\.app/Contents/MacOS/ghostty[[:space:]]|(^|[;&|[:space:]])ghostty[[:space:]]+(-e|--command|--title)'; then
    if ! print -r -- "$cmd" | grep -q -- '--title=claude-'; then
      jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
        permissionDecisionReason: "Ghostty windows Claude opens must be tagged so they get closed: pass --title=claude-<name> (e.g. open -na Ghostty.app --args --title=claude-dock ...). Tagged windows are killed automatically when the turn ends; close them yourself as soon as the screenshot is taken (pkill -f -- --title=claude-<name>)."}}'
    fi
  fi
  exit 0
fi

if [[ $mode == stop ]]; then
  pkill -f -- '--title=claude-' 2>/dev/null
  exit 0
fi
