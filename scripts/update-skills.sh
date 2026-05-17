#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Install (or re-download to latest) skills into .claude/skills/.
# `--force` makes install idempotent: it overwrites with the latest
# version, so re-running this script doubles as `gh skill update`.
install() {
  gh skill install "$@" --force --agent claude-code --scope project
}

install moonbitlang/moonbit-agent-guide moonbit-agent-guide
install moonbitlang/moonbit-agent-guide moonbit-refactoring
install microsoft/playwright-cli playwright-cli
