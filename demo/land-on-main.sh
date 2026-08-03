#!/usr/bin/env bash
#
# land-on-main.sh — simulate a teammate merging a change to `main` WHILE your
# stack is in review, then push it. After this runs, every branch in the stack
# is based on a now-stale `main` and must be re-synced (that's the whole point).
#
# Re-runnable: each run appends a distinct, timestamped entry, so you can fire
# it several times during a demo and run `gh stack sync` after each one.
#
# The change is intentionally additive so the cascading rebase is CLEAN — the
# pain being demonstrated is the orchestration, not conflict resolution. Want a
# conflict? See the CONFLICT VARIANT note at the bottom.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git checkout -q main

stamp="$(date +%H:%M:%S)"
echo "- Teammate change landed at ${stamp}" >> CHANGES.md

git add -A
git commit -q -m "chore: teammate change landed on main (${stamp})"

push=1
[[ "${1:-}" == "--no-push" ]] && push=0
if [[ $push -eq 1 ]]; then
    git push -q origin main
    echo "==> main moved AND pushed:"
else
    echo "==> main moved (local only, not pushed):"
fi
git --no-pager log --oneline -2 main | sed 's/^/    /'
echo
echo "Your stack is now behind main. Re-sync with:  gh stack sync"

# ── CONFLICT VARIANT ──────────────────────────────────────────
# To demo conflict handling, instead edit a file the stack also edits, e.g.
# rewrite src/tokens.js here (stack/foundation edits it). The rebase will then
# stop on a real conflict; resolve it once and continue with `gh stack rebase
# --continue` (gh stack still handles the ordering/pushing for you).
