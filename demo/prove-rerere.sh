#!/usr/bin/env bash
# Optional finale for the demo. Run this AFTER you've resolved the rebase
# conflict once. It rebuilds the identical conflict in a throwaway sandbox that
# reuses the resolution `git rerere` just recorded — so git resolves it from
# memory, with no manual editing. That's the real payoff for an 8-phase
# migration: the same conflicts recur every time `main` moves, and you resolve
# each of them only once, ever.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

GITDIR="$(git -C "$REPO_ROOT" rev-parse --absolute-git-dir)"
RRC="$GITDIR/rr-cache"
if [ ! -d "$RRC" ] || [ -z "$(ls -A "$RRC" 2>/dev/null)" ]; then
  warn "git rerere hasn't recorded anything yet."
  warn "Run the rebase step and resolve the conflict once first, then re-run this."
  exit 1
fi

say "Re-creating the exact same conflict in a sandbox to prove git rerere remembers it"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
(
  cd "$SANDBOX"
  git init -q
  git config user.email demo@example.com
  git config user.name "Demo"
  git config commit.gpgsign false
  git config rerere.enabled true
  git config rerere.autoupdate true
  # Reuse the resolution recorded during the live rebase.
  mkdir -p "$(git rev-parse --git-dir)/rr-cache"
  cp -R "$RRC/." "$(git rev-parse --git-dir)/rr-cache/"

  mkdir src
  cp "$SCENARIO_DIR/base/src/tokens.js" src/tokens.js
  git add -A && git commit -q -m "before the migration"
  git branch -m main
  git checkout -q -b teammate main
  cp "$SCENARIO_DIR/teammate/src/tokens.js" src/tokens.js
  git add -A && git commit -q -m "teammate token fix lands on main"
  git checkout -q -b phase1 main
  cp "$SCENARIO_DIR/phase1-foundation/src/tokens.js" src/tokens.js
  git add -A && git commit -q -m "phase 1 token annotation"

  printf '\n\033[1;34m▶ $ git rebase  (phase 1 onto the moved main — the same conflict as before)\033[0m\n'
  set +e
  git rebase teammate 2>&1 | sed 's/^/    /'
  set -e

  if [ -z "$(git diff --name-only --diff-filter=U)" ]; then
    GIT_EDITOR=true git rebase --continue >/dev/null 2>&1 || true
    printf '\033[1;32m  ✓ Same conflict detected — git resolved it from memory. Nothing to edit.\033[0m\n'
    printf '    Resolved line: %s\n' "$(grep 'medium:' src/tokens.js | sed 's/^ *//')"
  else
    printf '\033[1;33m  ! rerere did not replay (unexpected).\033[0m\n'
    git rebase --abort || true
  fi
)
ok "That one resolution is now replayed for every future rebase of this conflict — across all 8 phases."
