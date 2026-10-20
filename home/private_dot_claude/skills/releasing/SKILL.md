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
     correctly cut nothing. Say so and stop after step 6.
   - *Failed run*: `gh run view --log-failed`, report the cause, `git fetch origin` so the refs
     match, and stop. Do not push again or re-run the workflow to see if it passes; release
     failures are state (token, lockfile, commit) and a retry reproduces them.
6. **Sync the checkout:** `git pull --rebase origin main && git fetch --tags origin`, then
   `git branch --merged main | grep -vE '^\*|^\s*main$' | xargs -n1 git branch -d`, and
   `git fetch origin` if any push or pull used a URL instead of the remote name.
7. **Run the repo's post-release step** from its `Releasing` section (reinstall a tool, rebuild an
   artifact) and verify the installed version by the path that section names.
8. **Report:** version before → after, the release URL, and any repo that pins this package.
   The group repo's `AGENTS.md` (the parent folder) says who pins what. Bumping those is a
   separate release that needs its own go.

## Common mistakes

| Mistake | Instead |
| --- | --- |
| Watching the wrong run | Check the run's `headSha` is your commit before `gh run watch` |
| Calling it done because the run is green | Green means the workflow passed, not that a release exists. Compare tags |
| Re-running a failed release | Diagnose from the failed log first; a retry reproduces the same state |
| Bumping `package.json` or `pyproject.toml` | Never; the release commit does it and a manual bump breaks the pipeline |
| Deploying because a release happened | Deploy is its own step (jameson, tivan) and needs its own go |
