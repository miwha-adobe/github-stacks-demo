#!/usr/bin/env bash
#
# pain-setup.sh — set up Act 1 (today's manual-rebase pain), fully ISOLATED.
#
# Everything here lives on throwaway branches (pain/main, pain/foundation,
# pain/feature, pain/cleanup). It NEVER pushes and NEVER touches the real
# `main` or the `stack/*` branches that back the live PRs. Run it, do the
# manual cascade the runbook shows, then `./demo/reset.sh` to wipe it.
#
# After this runs, pain/main has moved ahead (a "teammate" landed a commit) and
# the pain/* stack is stale — exactly the situation that forces a manual,
# in-order rebase of every layer.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git checkout -q main

# Throwaway trunk that starts level with main.
git branch -f pain/main main

# Build the isolated 3-layer stack on top of it.
./demo/build-stack.sh "pain/" "pain/main" >/dev/null

# A teammate lands a change on the throwaway trunk (local only, never pushed).
git checkout -q pain/main
echo "- Teammate change landed at $(date +%H:%M:%S)" >> CHANGES.md
git add -A
git commit -q -m "chore: teammate change landed on pain/main"
git checkout -q pain/cleanup

echo
echo "==> Act 1 sandbox ready. pain/main has moved; the stack is stale:"
git --no-pager log --graph --oneline --decorate \
    pain/main pain/foundation pain/feature pain/cleanup | sed 's/^/    /'
echo
echo "Now do the manual cascade BY HAND (this is the pain):"
echo "    git rebase pain/main        pain/foundation"
echo "    git rebase pain/foundation  pain/feature"
echo "    git rebase pain/feature     pain/cleanup"
echo
echo "Three ordered rebases (and, for real PRs, three force-pushes)."
echo "When done: ./demo/reset.sh"
