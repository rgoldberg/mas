---
paths:
  - .github/workflows/**
  - Scripts/**
---

# Scripting

- Use zsh for scripts (except for shell-specific completion scripts)
- Zsh scripts must be compatible with all zsh versions starting with the version
  ([currently 5.9](https://opensource.apple.com/releases/)) bundled with the
  oldest macOS major version supported by mas ([currently
  15](../../Package.swift))
- Use `#!/bin/zsh -f` shebang (change options as necessary)
- Run `. "${0:A:h}/_setup-script"` at the start of all development scripts
- Override zsh settings from `. "${0:A:h}/_setup-script"` defaults as necessary
- Prefer concision over verbosity
- If performance is at least almost equivalent or better, prefer in descending
  order:
  - zsh expansions
  - zsh globs
  - zsh builtins
  - zsh loops
  - external commands
- Make variables local & readonly when possible
- Use:
  - `cp -c` instead of `cp`
  - `trash` instead of `rm`

## Releases

- Never delete a valid public version tag (one with a trusted SSH signature that
  is on `main`, as `tag-pushed.yaml` checks); `release-cancel` retains local
  version tags too
- Never add a step that applies the `pr-pull` label to a tap formula bump PR
  (e.g., to `tag-pushed.yaml`), because `mas-cli/homebrew-tap` is replacing it
