#!/usr/bin/env bash
#
# land-on-main.sh — simulate a teammate merging an unrelated change to `main`
# WHILE your stack is in flight. After this runs, every branch in the stack is
# based on a now-stale `main` and must be re-synced.
#
# The change is intentionally additive (a new file) so the cascading rebase is
# CLEAN — the pain being demonstrated is the orchestration (N rebases, in the
# right order, N force-pushes), not conflict resolution.
#
# Want to demo conflict handling too? Uncomment the CONFLICT VARIANT block
# below; it edits src/tokens.js, which stack/foundation also edits, so the
# rebase stops on a real conflict.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git checkout -q main

cat > src/version.js <<'EOF'
// Landed on main by a teammate while the stack was in review.
export const VERSION = '0.2.0';
EOF

# ── CONFLICT VARIANT (optional) ───────────────────────────────
# cat > src/tokens.js <<'EOF'
# // Shared tokens (edited on main — will conflict with stack/foundation).
# export const SIZES = ['xs', 's', 'm', 'l', 'xl'];
# export const VARIANTS = ['accent', 'neutral', 'positive', 'negative'];
# EOF
# ──────────────────────────────────────────────────────────────

git add -A
git commit -q -m "feat: add VERSION constant (landed on main)"
echo "==> main moved:"
git --no-pager log --oneline -2 main | sed 's/^/    /'
echo
echo "Your stack is now behind main. Time to re-sync."
