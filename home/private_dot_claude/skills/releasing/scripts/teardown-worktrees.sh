#!/usr/bin/env bash
# Remove every linked worktree whose work is already on main, with its branch.
# Prints one line per worktree: "removed <path>" or "kept <path>: <reason>".
# Nothing is removed unless its content is safe on main, so a kept worktree is
# a question for the user, never a failure to force past.
set -uo pipefail

root=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
cd "$root" || exit 1

if [ "$(git branch --show-current)" != main ]; then
  echo "stopped: $root is not on main" >&2
  exit 1
fi

# Ignored files worth keeping. `git worktree remove` deletes these without asking.
note_files() {
  local wt=$1 path
  {
    find "$wt/docs/superpowers" "$wt/.superpowers" -type f 2>/dev/null
    find "$wt" \( -name .git -o -name .venv -o -name node_modules \) -prune \
      -o -type f -name '.env*' -print
  } | while IFS= read -r path; do printf '%s\n' "${path#"$wt/"}"; done
}

# Files holding something main does not have. Empty output means safe to remove.
unsaved_files() {
  local wt=$1 file blob
  {
    git -C "$wt" -c core.quotePath=false diff --name-only HEAD
    git -C "$wt" -c core.quotePath=false ls-files --others --exclude-standard
  } | while IFS= read -r file; do
    # A blob anywhere in main's history means the edit landed, even if main moved on.
    if [ ! -f "$wt/$file" ]; then
      printf '%s\n' "$file"
      continue
    fi
    blob=$(git hash-object --no-filters "$wt/$file")
    [ -n "$(git log -1 main --find-object="$blob" --format=%h)" ] || printf '%s\n' "$file"
  done
  note_files "$wt" | while IFS= read -r file; do
    [ -f "$file" ] || continue
    # Process substitution: diff exits 1 on any difference, which pipefail would turn into a false.
    if grep -q '^<' <(diff "$wt/$file" "$file"); then printf '%s\n' "$file"; fi
  done
}

teardown() {
  local wt=$1 branch=$2 delete_flag unsaved file

  if [ -z "$branch" ]; then
    echo "kept $wt: detached HEAD"
    return
  fi

  if git merge-base --is-ancestor "$branch" main; then
    delete_flag=-d
  elif [ "$(gh pr list --state merged --head "$branch" --json headRefOid \
    --jq '.[0].headRefOid' 2>/dev/null)" = "$(git rev-parse "$branch")" ]; then
    delete_flag=-D # squash merge: the tip is not an ancestor, but the PR proves it landed
  else
    echo "kept $wt: branch $branch is not merged"
    return
  fi

  unsaved=$(unsaved_files "$wt" | sort -u | tr '\n' ' ')
  if [ -n "$unsaved" ]; then
    echo "kept $wt: not on main: $unsaved"
    return
  fi

  # Ignored from here on, so copying cannot dirty main.
  note_files "$wt" | while IFS= read -r file; do
    if [ ! -e "$file" ]; then
      mkdir -p "$(dirname "$file")"
      cp -p "$wt/$file" "$file"
      echo "copied $file"
    fi
  done

  if ! git worktree remove --force "$wt" 2>/dev/null; then
    echo "kept $wt: git refused to remove it"
    return
  fi
  git branch "$delete_flag" "$branch" >/dev/null
  echo "removed $wt"
}

git worktree list --porcelain | awk '
  /^worktree / { if (n++) print path "\t" branch; path = substr($0, 10); branch = "" }
  /^branch /   { branch = substr($0, 19) }
  END          { print path "\t" branch }
' | tail -n +2 | {
  # Read the whole list first: removing a worktree changes it.
  entries=$(cat)
  while IFS=$'\t' read -r wt branch; do
    [ -n "$wt" ] && teardown "$wt" "$branch"
  done <<<"$entries"
}
git worktree prune
