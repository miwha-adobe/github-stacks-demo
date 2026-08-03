#!/usr/bin/env bash
#
# build-stack.sh — build a 3-layer stack of branches.
#
#   <trunk>
#    |_ <prefix>foundation   shared dev-warning helper + tokens
#        |_ <prefix>feature   validation logic that USES the foundation
#            |_ <prefix>cleanup   wire up exports + docs
#
# Usage:
#   ./demo/build-stack.sh [prefix] [trunk]
#     prefix   branch-name prefix   (default: "stack/")
#     trunk    base branch          (default: "main")
#
# Defaults build the REAL stack (stack/* on main) that backs the demo PRs — this
# was already run during setup. The pain sandbox reuses it as:
#   ./demo/build-stack.sh "pain/" "pain/main"
#
# Idempotent: deletes the target prefix's branches first, so re-running gives
# identical state.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PREFIX="${1:-stack/}"
TRUNK="${2:-main}"
FOUNDATION="${PREFIX}foundation"
FEATURE="${PREFIX}feature"
CLEANUP="${PREFIX}cleanup"

echo "==> Building on trunk '$TRUNK' with prefix '$PREFIX'"
git checkout -q "$TRUNK"
for b in "$CLEANUP" "$FEATURE" "$FOUNDATION"; do
    git branch -D "$b" >/dev/null 2>&1 || true
done

# ── Layer 1: foundation — shared, depended-upon code ──
git checkout -q -b "$FOUNDATION" "$TRUNK"
cat > src/warn.js <<'EOF'
// Dev-only warning helper. Foundational: other layers build on this.
const seen = new Set();

export function warnOnce(key, message) {
    if (process.env.NODE_ENV === 'production') return;
    if (seen.has(key)) return;
    seen.add(key);
    // eslint-disable-next-line no-console
    console.warn(`[github-stacks-demo] ${message}`);
}
EOF
cat > src/tokens.js <<'EOF'
// Shared tokens used across the library.
export const SIZES = ['s', 'm', 'l', 'xl'];
export const VARIANTS = ['accent', 'neutral', 'positive', 'negative'];
EOF
git add -A
git commit -q -m "feat(foundation): add dev-warning helper and shared tokens"

# ── Layer 2: feature — depends on the foundation ──
git checkout -q -b "$FEATURE" "$FOUNDATION"
cat > src/validate.js <<'EOF'
// Validation logic. DEPENDS ON the foundation layer (warn + tokens).
import { warnOnce } from './warn.js';
import { SIZES, VARIANTS } from './tokens.js';

export function validateSize(value) {
    if (!SIZES.includes(value)) {
        warnOnce(`size:${value}`, `"${value}" is not a valid size. Expected one of: ${SIZES.join(', ')}.`);
        return false;
    }
    return true;
}

export function validateVariant(value) {
    if (!VARIANTS.includes(value)) {
        warnOnce(`variant:${value}`, `"${value}" is not a valid variant. Expected one of: ${VARIANTS.join(', ')}.`);
        return false;
    }
    return true;
}
EOF
git add -A
git commit -q -m "feat(validate): add size and variant validation on top of foundation"

# ── Layer 3: cleanup — depends on the feature ──
git checkout -q -b "$CLEANUP" "$FEATURE"
cat > src/index.js <<'EOF'
// Public entry point for the library.

export const NAME = 'github-stacks-demo';
export { warnOnce } from './warn.js';
export { SIZES, VARIANTS } from './tokens.js';
export { validateSize, validateVariant } from './validate.js';
EOF
mkdir -p docs
cat > docs/validation.md <<'EOF'
# Validation

```js
import { validateSize, validateVariant } from 'github-stacks-demo';

validateSize('m'); // true
validateSize('xxl'); // false, warns once in dev
validateVariant('accent'); // true
```
EOF
git add -A
git commit -q -m "docs(validate): export validators and document usage"

git checkout -q "$TRUNK"
echo "==> Built. Layout:"
git --no-pager log --graph --oneline --decorate "$TRUNK" "$FOUNDATION" "$FEATURE" "$CLEANUP" | sed 's/^/    /'
