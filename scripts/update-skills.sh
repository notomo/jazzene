#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# moonbit skills
TMP_MOONBIT=/tmp/moonbit-skills-update
git clone --depth=1 https://github.com/moonbitlang/moonbit-agent-guide "$TMP_MOONBIT"
cp -r "$TMP_MOONBIT/moonbit-agent-guide/." "$REPO_ROOT/.claude/skills/moonbit-agent-guide/"
cp -r "$TMP_MOONBIT/moonbit-refactoring/." "$REPO_ROOT/.claude/skills/moonbit-refactoring/"
rm -rf "$TMP_MOONBIT"

# playwright-cli skill
TMP_PLAYWRIGHT=/tmp/playwright-cli-skill-update
git clone --depth=1 https://github.com/microsoft/playwright-cli "$TMP_PLAYWRIGHT"
cp -r "$TMP_PLAYWRIGHT/skills/playwright-cli/." "$REPO_ROOT/.claude/skills/playwright-cli/"
rm -rf "$TMP_PLAYWRIGHT"
