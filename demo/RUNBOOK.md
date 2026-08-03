# GitHub Stacks — 5-minute demo runbook

**What this proves:** the thing that hurts today — rebasing a multi-phase migration when
`main` moves — becomes essentially **two commands**, and conflicts you resolve **once** are
replayed automatically for the life of the migration.

The demo migrates a component's API in **4 phases** (standing in for your 8). Each phase is a
PR that targets the phase below it — a *stack*. We use GitHub's own tooling: the
[`gh stack`](https://gh.io/stacks) CLI extension and the stack UI on github.com.

---

## Before the meeting (once, ~30s)

```bash
demo/setup.sh
```

This builds the 4-phase stack + PRs and a "teammate" PR you'll merge live. Then open two
browser tabs:

1. The **bottom** stack PR — *phase 1* (its merge box shows the **stack map**).
2. The **teammate** PR (`fix(tokens): set medium size to 12 and add xlarge`).

Keep a terminal in the repo. `setup.sh` leaves you checked out on `phase1-foundation`.

> Re-running? `demo/reset.sh` then `demo/setup.sh` returns everything to a clean slate.

---

## The script

### ① See the stack — CLI + UI (~45s)

> **Say:** "We're migrating a component's API in 4 phases. Each phase is its own PR that
> builds on the one below — that's a stack. Today these are 4 branches I keep in sync by hand."

```bash
gh stack view
```

Point out: four phases, bottom → top, each linked to a PR, each targeting the branch below.
Switch to the browser, show the **stack map** in the bottom PR's merge box, and click up the
stack so the audience sees the dependency chain and that reviewers can read one layer at a time.

> **Say:** "Now watch what happens when `main` moves underneath all of this."

### ② Main moves → one cascading rebase (the payoff, ~2.5m)

Merge the **teammate PR** in the browser (or run the command). This is `main` moving.

```bash
gh pr merge teammate/token-fix --squash --delete-branch
```

> **Say:** "A teammate just landed an unrelated token fix on `main`. My whole stack is now
> behind. Old way: rebase phase 1, fix conflicts, rebase phase 2 onto that, and so on — then
> re-point every PR's base by hand. New way:"

```bash
gh stack rebase
```

It fetches `main` and cascades a rebase up the stack. It stops at **phase 1** with one real
conflict in `src/tokens.js` — the exact line the teammate changed:

```js
<<<<<<< HEAD
  medium: 12,
=======
  medium: 16, // legacy default; see migration phase 1
>>>>>>> phase 1: foundation …
```

Resolve it to keep the teammate's value **and** your comment, then continue:

```bash
# edit src/tokens.js -> `  medium: 12, // legacy default; see migration phase 1`
git add src/tokens.js
gh stack rebase --continue
```

Phases 2 → 4 rebase automatically. Push the restacked branches:

```bash
gh stack push
```

> **Say:** "One command restacked all four phases with a *single* resolution. At 8 phases the
> old way is 8 rebases and re-resolving the same conflict over and over."

**The `rerere` payoff** — resolve once, forever:

```bash
demo/prove-rerere.sh
```

It re-triggers the identical conflict; git prints **“Resolved 'src/tokens.js' using previous
resolution”** and finishes with no editing.

> **Say:** "`gh stack init` turned on `git rerere`. That resolution is now remembered — so every
> future time `main` moves and this conflict recurs, across all 8 phases, it resolves itself."

### ③ Merge the bottom → auto-retarget → sync (~1m)

In the browser, **merge the bottom PR (phase 1)**.

> **Say:** "Phase 1 is in `main`. Watch phase 2 — GitHub automatically retargeted its base to
> `main` and rebased the rest. I didn't touch a single PR base."

Show phase 2's PR now targeting `main`. Then clean up locally:

```bash
gh stack sync --prune
```

```bash
gh stack view
```

> **Say:** "`sync` pulled the merge into `main`, restacked the remaining phases, pushed, and
> deleted the merged branch. When the migration's ready, `gh stack merge` lands the rest of the
> stack atomically — all or nothing."

### Wrap (~30s)

> **Say:** "The whole manual rebase dance became two commands: `gh stack rebase` when `main`
> moves, `gh stack sync --prune` after a merge — plus `rerere` so a conflict is solved once for
> the life of the migration. Same flow at 8 phases, and it works from the web UI, the CLI,
> mobile, and coding agents."

---

## If something goes sideways

| Situation | Fix |
| --- | --- |
| Rebase looks wrong mid-flight | `gh stack rebase --abort` (restores every branch) |
| Want to start the whole demo over | `demo/reset.sh` then `demo/setup.sh` |
| A command is waiting on a prompt | most accept `--auto` / `--yes` |
| Lost track of where you are | `gh stack view` |

## Command cheat sheet

| Command | Does |
| --- | --- |
| `gh stack view` | Show the stack, its PRs, and status |
| `gh stack rebase` | Cascading rebase of the whole stack onto its parents / `main` |
| `gh stack rebase --continue` / `--abort` | Resume after resolving / undo everything |
| `gh stack push` | Push restacked branches (`--force-with-lease`) |
| `gh stack sync --prune` | Fetch + rebase + push + sync PR state, drop merged branches |
| `gh stack merge` | Atomically merge some/all of the stack |
| `gh stack up` / `down` / `top` / `bottom` | Move between layers |

## How this maps to your 8-phase migrations

- **4 phases here → 8 in real life.** The commands and the number of manual resolutions don't
  grow with the stack; `gh stack rebase` is still one command.
- **`main` moves repeatedly** over a long migration. `rerere` (enabled by `gh stack init`) means
  each recurring conflict is resolved once, then replayed — the single biggest rebase time-sink,
  gone.
- **Lower-phase fixes** (a reviewer asks you to change phase 2) are the same story: fix it, run
  `gh stack rebase`, and everything above restacks in one shot.
