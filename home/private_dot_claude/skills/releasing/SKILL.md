---
name: releasing
description: Use when the user asks to release, ship or publish one of their repos, or right after any push to main in a repo that uses semantic-release
---

# Releasing

Every repo releases the same way: semantic-release reads conventional commits on `main` and the
GitHub Actions `Release` workflow cuts the version, tag and GitHub release. Nobody bumps a version
by hand. The global instructions decide *whether* to release (only on an explicit go, one go per
release); this skill is *how*.

## Procedure

1. **Read the repo's `Releasing` section in `AGENTS.md`.** It names the pre-push checks and the
   post-release step. Run the checks and fix failures before pushing.
2. **Note the current release** so the outcome can be verified: `gh release list --limit 1`.
3. **Push:** `git push origin main`.
4. **Watch the run to the end.** The run for your push starts a few seconds after it, so make
   sure the latest run is yours before watching:
   `gh run list --workflow Release --limit 1 --json databaseId,headSha` must show
   `git rev-parse HEAD`; then `gh run watch <databaseId>`.
5. **Read the outcome.** It is one of three:
   - *New release*: `gh release list --limit 1` shows a new tag. Continue.
   - *Green run, same tag*: the commits were `chore`, `docs`, `ci` or similar and semantic-release
     correctly cut nothing. Say so, skip step 7, and continue.
   - *Failed run*: `gh run view --log-failed`, report the cause, `git fetch origin` so the refs
     match, and stop. Do not push again or re-run the workflow to see if it passes; release
     failures are state (token, lockfile, commit) and a retry reproduces them. Worktrees stay,
     because the fix may need them.
6. **Sync the checkout:** from the main checkout, never a worktree,
   `git pull --rebase origin main && git fetch --tags origin`, and `git fetch origin` if any push
   or pull used a URL instead of the remote name.
7. **Run the repo's post-release step** from its `Releasing` section (reinstall a tool, rebuild an
   artifact) in the main checkout, and verify the installed version by the path that section
   names. A repo whose `Releasing` section names no such step skips this.
8. **Tear down finished worktrees:** each holds a full `.venv` or `node_modules`, so none may
   outlive its branch. This covers every linked worktree of the repo, whichever release finished
   it. Run the script, then delete the merged branches it left:
   ```bash
   bash ~/.claude/skills/releasing/scripts/teardown-worktrees.sh
   git branch --merged main | grep -vE '^[*+]|^\s*main$' | xargs -n1 git branch -d
   ```
   The script removes a worktree and its branch only when everything in it is safe on `main`, and
   copies ignored plans and notes missing from the main checkout first. For each `kept` line it
   prints, leave that worktree in place and put the line in the report: what to do with it is the
   user's call.
9. **Report:** version before → after, the release URL, any worktree the script kept, and any repo
   that pins this package. The group repo's `AGENTS.md` (the parent folder) says who pins what.
   Bumping those is a separate release that needs its own go.

## Common mistakes

| Mistake | Instead |
| --- | --- |
| Watching the wrong run | Check the run's `headSha` is your commit before `gh run watch` |
| Calling it done because the run is green | Green means the workflow passed, not that a release exists. Compare tags |
| Re-running a failed release | Diagnose from the failed log first; a retry reproduces the same state |
| Bumping `package.json` or `pyproject.toml` | Never; the release commit does it and a manual bump breaks the pipeline |
| Installing or building from a worktree | Install from the main checkout after the sync, so the tool matches the release |
| Running `git worktree remove` by hand | It deletes ignored plans and `.env` silently, and "merged" can mean a branch with no commits and all its work uncommitted. Use the script |
| Using `--force` on a worktree the script kept | The script kept it because something there is not on `main`. Report it and ask |
| Deploying because a release happened | Deploy is its own step (jameson, tivan) and needs its own go |
