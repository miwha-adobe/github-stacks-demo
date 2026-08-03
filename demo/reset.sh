#!/usr/bin/env bash
#
# reset.sh — tidy up between rehearsals.
#
#   * deletes the Act 1 pain sandbox (pain/*)
#   * restores local `main` to match origin/main
#   * leaves the real stack/* branches (which back the live PRs) UNTOUCHED
#
# It does NOT delete or alter your PRs. To re-hydrate local tracking of the
# live stack after a reset, use:  gh stack checkout 1   (or any stack PR number)

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git checkout -q main
git fetch -q origin
git reset -q --hard origin/main

for b in pain/cleanup pain/feature pain/foundation pain/main; do
    git branch -D "$b" >/dev/null 2>&1 || true
done

echo "==> Reset: local main == origin/main; pain sandbox removed; stack/* left intact."
git --no-pager log --oneline -1 | sed 's/^/    /'
