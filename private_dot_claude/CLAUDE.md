# Working preferences

These apply in every project. A repo's own `AGENTS.md` adds to them.

## Git and releases

- **Never commit unless I explicitly ask.** Not when a plan or skill includes commit steps, and not for small chores. "Run the tests and push" is not permission to commit. Finish the change, show it, and ask.
- **Never push, open a PR, merge or release unless I explicitly ask.** When implementation is done, keep the branch local, say it is ready to test, and stop. Approval for one release never covers a later one.
- **Unrelated file changes:** when files I did not ask about show up while staging or committing (formatter churn, stray config edits), stop, list them and ask whether to include, revert or leave them. Never stash, discard or revert them on your own.
- **After every release, sync the local checkout without being asked:** pull the release commit, fetch tags, refresh remote-tracking refs, delete merged branches, and reinstall or verify any locally installed tool. If a push or pull used an explicit URL instead of the named remote, finish with `git fetch origin` so tracking refs are not stale.

## How to work with me

- **Questions are not build orders.** Treat questions and musings ("I wonder if…", "should we…", "what do you think…") as discussion: answer and propose, then wait for an explicit go before changing anything. If unsure whether it is a request, ask.
- **Execute implementation plans inline** in the main session. Do not use subagent-driven plan execution and do not ask which mode to use.
- **Project instructions live in `AGENTS.md`.** Do not create a `CLAUDE.md` in a repo; Claude Code reads `AGENTS.md` natively. Durable project rules go there, not into assistant memory, which is for personal and in-flight context only.

## This machine

- **SSH keys come from the 1Password SSH agent.** An empty agent or `signing failed … communication with agent failed` means 1Password is locked or an approval prompt was missed: ask me to unlock and retry. Never suggest `ssh-add`. An HTTPS URL is an acceptable temporary workaround.
- **The `gh` token has no `workflow` scope.** Push commits that touch `.github/workflows/*` over SSH.
- **`docs/superpowers/` is globally gitignored.** Never force-add ignored paths, and check each repo's own rules for whether specs and plans are committed at all.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
