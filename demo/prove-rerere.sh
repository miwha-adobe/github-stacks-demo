#!/usr/bin/env bash
# Optional finale for the demo. Run this AFTER you've resolved the rebase
# conflict once. It re-creates the exact same conflict on a throwaway branch;
# because `git rerere` recorded your resolution, git replays it automatically —
# no manual editing. This is the payoff for an 8-phase migration where the same
# conflicts recur every time the trunk moves.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [ "$(git config --get rerere.enabled)" != "true" ]; then
  warn "git rerere is not enabled — run demo/setup.sh first."
  exit 1
fi

say "Re-creating the exact same conflict to prove git rerere remembers it"
git fetch "$REMOTE" >/dev/null 2>&1 || true

seed="$(git merge-base "$REMOTE/$TRUNK" "${STACK_BRANCHES[0]}")"
git checkout -q -B rerere-proof "$seed"
cp -R "$SCENARIO_DIR/${STACK_BRANCHES[0]}/src/." src/
git add -A
git commit -q -m "replay: phase 1 token annotation"

say "Rebasing onto $TRUNK — same medium-line conflict as before…"
set +e
git rebase "$REMOTE/$TRUNK"
rc=$?
set -e

if [ $rc -eq 0 ]; then
  ok "Rebase completed with no conflict."
elif [ -z "$(git diff --name-only --diff-filter=U)" ]; then
  ok "rerere auto-resolved the conflict — no manual editing needed."
  GIT_EDITOR=true git rebase --continue >/dev/null
  ok "Rebase continued and finished automatically."
else
  warn "Conflict was NOT auto-resolved (is rerere on?). Aborting."
  git rebase --abort
fi

# Clean up the throwaway branch.
git checkout -q "${STACK_BRANCHES[0]}" 2>/dev/null || git checkout -q "$TRUNK" 2>/dev/null || true
git branch -D rerere-proof >/dev/null 2>&1 || true
ok "Done — that resolution is remembered for every future rebase of this conflict."
