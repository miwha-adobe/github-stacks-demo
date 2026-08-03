# Shared config + helpers for the GitHub Stacks demo scripts.
# Sourced by setup.sh, reset.sh, and prove-rerere.sh — not run directly.

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCENARIO_DIR="$REPO_ROOT/demo/scenario"

TRUNK="main"
REMOTE="origin"

# Bottom -> top order of the migration stack.
STACK_BRANCHES=(phase1-foundation phase2-variants phase3-validate phase4-cleanup)

# Commit subjects double as the auto-generated PR titles.
STACK_SUBJECTS=(
  "phase 1: foundation — options-object API alongside the legacy string"
  "phase 2: variants — resolve variants to a full style object"
  "phase 3: validate — option validation and shared defaults"
  "phase 4: cleanup — drop the legacy positional API"
)

TEAMMATE_BRANCH="teammate/token-fix"
TEAMMATE_SUBJECT="fix(tokens): set medium size to 12 and add xlarge"
RESTORE_BRANCH="demo/restore-main"

say()  { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }

require_clean_worktree() {
  if [ -n "$(git status --porcelain)" ]; then
    warn "You have uncommitted changes or an in-progress rebase."
    warn "Run demo/reset.sh (or commit/stash) before running this script."
    exit 1
  fi
}

abort_in_progress() {
  git rebase --abort >/dev/null 2>&1 || true
  git merge --abort  >/dev/null 2>&1 || true
  git cherry-pick --abort >/dev/null 2>&1 || true
}

teardown_demo() {
  say "Tearing down any previous demo state"
  abort_in_progress
  git fetch "$REMOTE" --prune >/dev/null 2>&1 || true

  local branches=("${STACK_BRANCHES[@]}" "$TEAMMATE_BRANCH" "$RESTORE_BRANCH")

  # Close open PRs (this also deletes their remote branch).
  local b num
  for b in "${branches[@]}"; do
    num="$(gh pr list --state open --head "$b" --json number --jq '.[0].number' 2>/dev/null || true)"
    if [ -n "${num:-}" ]; then
      gh pr close "$num" --delete-branch >/dev/null 2>&1 && ok "Closed PR #$num ($b), deleted its branch" || true
    fi
  done

  # Delete any remaining remote branches (e.g. submitted but no open PR).
  for b in "${branches[@]}"; do
    git push "$REMOTE" --delete "$b" >/dev/null 2>&1 && ok "Deleted remote branch $b" || true
  done

  # Delete local branches (move to trunk first so we can delete them).
  git checkout "$TRUNK" >/dev/null 2>&1 || true
  for b in "${branches[@]}"; do
    git branch -D "$b" >/dev/null 2>&1 && ok "Deleted local branch $b" || true
  done

  # Clear gh stack local tracking and any recorded rerere resolutions so the
  # next demo starts fresh — the first conflict must be resolved by hand before
  # rerere can replay it.
  local gitdir; gitdir="$(git rev-parse --git-dir)"
  rm -f "$gitdir/gh-stack" "$gitdir/gh-stack.lock" 2>/dev/null || true
  rm -rf "$gitdir/rr-cache" 2>/dev/null || true
}

# If any migration change was merged into the trunk, open + merge a small PR
# that restores the whole baseline library so the demo can be run again cleanly.
restore_main_to_base() {
  git fetch "$REMOTE" >/dev/null 2>&1 || true

  # Nothing to restore if the sample library isn't on the trunk yet.
  git cat-file -e "$REMOTE/$TRUNK:src/tokens.js" 2>/dev/null || return 0

  git branch -D "$RESTORE_BRANCH" >/dev/null 2>&1 || true
  git checkout -q -B "$RESTORE_BRANCH" "$REMOTE/$TRUNK"
  rm -rf src
  cp -R "$SCENARIO_DIR/base/src" src
  git add -A
  if git diff --cached --quiet; then
    git checkout -q "$TRUNK" 2>/dev/null || true
    git branch -D "$RESTORE_BRANCH" >/dev/null 2>&1 || true
    return 0  # trunk already at baseline
  fi

  say "Restoring $TRUNK to the baseline library (a migration change had been merged)"
  git commit -q -m "chore(demo): restore baseline library on $TRUNK"
  git push -q -u "$REMOTE" "$RESTORE_BRANCH"
  gh pr create --base "$TRUNK" --head "$RESTORE_BRANCH" \
    --title "chore(demo): restore baseline library" \
    --body "Resets src/ to the demo baseline so the stack demo can be re-run from a known state." >/dev/null 2>&1 || true
  gh pr merge "$RESTORE_BRANCH" --squash --delete-branch >/dev/null 2>&1 \
    || gh pr merge "$RESTORE_BRANCH" --squash --delete-branch --admin >/dev/null 2>&1 \
    || warn "Could not auto-merge the restore PR — merge it manually, then re-run."
  git checkout -q "$TRUNK" 2>/dev/null || true
  git branch -D "$RESTORE_BRANCH" >/dev/null 2>&1 || true
  git fetch "$REMOTE" >/dev/null 2>&1 || true
  git reset -q --hard "$REMOTE/$TRUNK" 2>/dev/null || true
  ok "Trunk restored to the baseline library"
}
