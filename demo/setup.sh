#!/usr/bin/env bash
# Builds the GitHub Stacks demo: a 4-phase migration stack (4 linked PRs) plus a
# teammate PR that you merge live to make the trunk move under the stack.
#
# Safe to re-run — it tears down and rebuilds from a known state each time.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

say "Setting up the GitHub Stacks demo"

# The sample library must already be on the trunk.
git fetch "$REMOTE" --prune >/dev/null 2>&1 || true
if ! git cat-file -e "$REMOTE/$TRUNK:src/component.js" 2>/dev/null; then
  warn "origin/$TRUNK does not contain the sample library yet."
  warn "Merge the demo tooling PR into $TRUNK first, then re-run this script."
  exit 1
fi

# Start from a clean slate (idempotent re-runs).
teardown_demo
restore_main_to_base
git fetch "$REMOTE" >/dev/null 2>&1 || true

# git rerere is what remembers a conflict resolution and replays it automatically.
# `gh stack init` enables this for you; we also set it explicitly so the demo is
# self-contained no matter how the repo was cloned.
git config rerere.enabled true
git config rerere.autoupdate true

say "Building the ${#STACK_BRANCHES[@]}-phase migration stack locally"
parent="$REMOTE/$TRUNK"
for i in "${!STACK_BRANCHES[@]}"; do
  b="${STACK_BRANCHES[$i]}"
  git checkout -q -B "$b" "$parent"
  cp -R "$SCENARIO_DIR/$b/src/." src/
  git add -A
  git commit -q -m "${STACK_SUBJECTS[$i]}"
  ok "Built $b"
  parent="$b"
done

say "Creating the stack and its pull requests on GitHub"
gh stack init "${STACK_BRANCHES[@]}"
gh stack submit --auto --open

say "Creating the teammate PR (leave it OPEN — you merge it live during the demo)"
git checkout -q -B "$TEAMMATE_BRANCH" "$REMOTE/$TRUNK"
cp -R "$SCENARIO_DIR/teammate/src/." src/
git add -A
git commit -q -m "$TEAMMATE_SUBJECT"
git push -q -u "$REMOTE" "$TEAMMATE_BRANCH"
gh pr create --base "$TRUNK" --head "$TEAMMATE_BRANCH" \
  --title "$TEAMMATE_SUBJECT" \
  --body "A small, unrelated token fix on \`$TRUNK\`. Merge this during the demo to make the trunk move under the open stack." >/dev/null
ok "Teammate PR created"

# Drop the presenter at the bottom of the stack.
gh stack checkout "${STACK_BRANCHES[0]}" >/dev/null 2>&1 || git checkout -q "${STACK_BRANCHES[0]}"

say "Setup complete — here is your stack"
gh stack view || true
printf '\n'
ok "You're ready. Walk through demo/RUNBOOK.md."
