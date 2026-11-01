# dotfiles — Agent Guidelines

chezmoi source for the Macs. `.chezmoiroot` points at `home/`, so only that folder reaches `$HOME`.
Everything else (this file, `install.sh`, `packages/`) stays in the repo.

The repo is public: hosts, addresses, emails and employer names come from 1Password, never from a
file here. CI enforces this with the `FORBIDDEN_PATTERNS` secret.

## Releasing

semantic-release cuts versions from conventional commits on `main`; follow the global `releasing`
skill, with these differences:

- **The workflow is `CI`, not `Release`.** The `Release` job runs after both `Verify` jobs pass, so
  watch with `gh run list --workflow CI`.
- **The major version is the target macOS major.** `.releaserc.json` turns a breaking change into a
  minor bump, so automation never leaves the current major. For a new macOS, tag `<major>.0.0` by
  hand on `main`, push the tag and create its GitHub release; later releases continue from it.
- **`feat!:` and `fix!:` count as breaking.** The default parser ignores the `!` and cuts nothing, so
  `parserOpts` in `.releaserc.json` adds it. Keep it in both plugins.
- **Tags have no `v` prefix**, and a release adds no commit to `main`.

Before pushing, `sh -n install.sh` must pass. CI does the rest.

Post-release step: `chezmoi apply` with 1Password unlocked, to bring this Mac up to the release.
Fresh installs clone `main`, so they do not depend on a release.
