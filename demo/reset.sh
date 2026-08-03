#!/usr/bin/env bash
#
# reset.sh — return the repo to the clean base state (just `main` at demo-base),
# deleting all stack branches and any "landed on main" commits. Run this between
# rehearsals.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git checkout -q main
git reset -q --hard demo-base
for b in stack/foundation stack/feature stack/cleanup; do
    git branch -D "$b" >/dev/null 2>&1 || true
done
# Clean up the teammate's file if a previous run left it in the working tree.
rm -f src/version.js
echo "==> Reset to demo-base:"
git --no-pager log --oneline -1 | sed 's/^/    /'
