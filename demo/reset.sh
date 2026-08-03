#!/usr/bin/env bash
# Tears the demo down to a clean slate: closes the stack + teammate PRs, deletes
# their branches (local and remote), clears gh stack tracking, and restores the
# trunk baseline if a token change had been merged. Run this between rehearsals.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

say "Resetting the GitHub Stacks demo to a clean slate"
teardown_demo
restore_main_to_base
ok "Reset complete. Run demo/setup.sh to rebuild the demo."
