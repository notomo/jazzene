---
name: commit
description: Create a git commit. Use when user says "commit", or asks to commit changes.
---

# Commit

Run these commands only, in this order:

1. `git status` and `git diff HEAD` (in parallel)
2. `git add <specific files>` — stage relevant files individually
3. `git commit -m "type(scope): description" -m "Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"` — use two `-m` flags (no heredoc, no `$()`)

## Commit message format

Use two separate `-m` flags:
- First `-m`: `type(scope): short description`
- Second `-m`: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`

Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`

Scope: always include. Use the package name or the central file/component being changed (e.g. `music`, `ui`, `audio`, `generator`, `sheet`).

Do not run any other commands.
