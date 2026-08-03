#!/usr/bin/env bash
#
# build-stack.sh — (re)build the 3-layer demo stack from a clean `main`.
#
# Layers (each depends on the one below it):
#
#   main
#    └─ stack/foundation   shared dev-warning helper + tokens
#        └─ stack/feature   validation logic that USES the foundation
#            └─ stack/cleanup   wire up exports + docs
#
# Idempotent: deletes any existing stack/* branches and rebuilds them, so you
# can run it before every rehearsal and get identical state.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

echo "==> Resetting to a clean main"
git checkout -q main
# Drop any previous run's branches.
for b in stack/foundation stack/feature stack/cleanup; do
    git branch -D "$b" >/dev/null 2>&1 || true
done

# ─────────────────────────────────────────────
# Layer 1: foundation — shared, depended-upon code
# ─────────────────────────────────────────────
echo "==> Building stack/foundation"
git checkout -q -b stack/foundation main

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

# ─────────────────────────────────────────────
# Layer 2: feature — depends on the foundation
# ─────────────────────────────────────────────
echo "==> Building stack/feature"
git checkout -q -b stack/feature stack/foundation

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

# ─────────────────────────────────────────────
# Layer 3: cleanup — depends on the feature
# ─────────────────────────────────────────────
echo "==> Building stack/cleanup"
git checkout -q -b stack/cleanup stack/feature

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

git checkout -q main
echo
echo "==> Stack built. Layout:"
git --no-pager log --graph --oneline --decorate main stack/foundation stack/feature stack/cleanup | sed 's/^/    /'
