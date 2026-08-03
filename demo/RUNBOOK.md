# GitHub Stacks demo runbook

A ~7 minute live demo. The whole point is one pain: **rebasing a stack when
`main` moves or a lower branch changes.** We show today's manual pain first,
then the same thing with GitHub's native stacked pull requests.

> **Setup:** GitHub Stacks is a native feature (public preview, July 30 2026).
> It ships as a CLI extension:
>
> ```bash
> gh auth login                        # once, if not already authenticated
> gh extension install github/gh-stack # once
> ```

## The example

A change that naturally splits into three dependent layers:

```
main
 └─ foundation   shared dev-warning helper + tokens
     └─ feature   size/variant validation that USES the foundation
         └─ cleanup   wire up exports + docs
```

`feature` can't exist without `foundation`; `cleanup` can't exist without
`feature`. That dependency is what makes it a stack, and what makes rebasing
painful.

## Cheat sheet (`gh stack`)

| Command | What it does |
| --- | --- |
| `gh stack init` | Start a stack on top of `main` |
| `gh stack add <branch>` | Add a layer on top of the current one |
| `gh stack view` | Show the stack, ordering, and PR links |
| `gh stack submit` | Push all branches, open/update every PR with the right base |
| `gh stack sync` | **Fetch, rebase the whole stack onto fresh `main`, push, sync PR state — one command** |
| `gh stack rebase --upstack` | Cascade the current branch's change into every branch above it |
| `gh stack up` / `down` / `top` / `bottom` | Move around the stack |
| `gh stack merge` | Merge stacked PRs into the base |

---

## Act 1 — today's pain (plain git)

Frame it: "this is what we do now, by hand."

```bash
./demo/reset.sh          # clean slate: just main
./demo/build-stack.sh    # builds foundation -> feature -> cleanup as plain branches
```

Show the stack you just built:

```bash
git log --graph --oneline --decorate main stack/foundation stack/feature stack/cleanup
```

Now a teammate merges something to `main` while your stack is in review:

```bash
./demo/land-on-main.sh   # adds a VERSION constant on main
```

Your entire stack is now based on a stale `main`. To re-sync by hand you must
rebase **each branch onto its parent, in order** — miss one and the upper
branches silently keep building on old code:

```bash
git rebase main            stack/foundation   # 1
git rebase stack/foundation stack/feature     # 2
git rebase stack/feature   stack/cleanup      # 3
```

(You'll see harmless `skipped previously applied commit` warnings — that's git
noticing commits already upstream.) Then, if these were real PRs, you'd
`git push --force-with-lease` **three times** and check that no PR base drifted.

**The talking point:** three branches is annoying; six or eight is a genuine
tax, and the ordering is on you. This is the thing everyone quietly hates.

---

## Act 2 — the GitHub Stacks way

Reset and rebuild, but this time the stack is tracked by `gh stack`.

> The exact adoption commands are verified live during the demo (see the
> "Verified commands" note at the bottom, filled in after a real run). The
> documented flow is:

```bash
./demo/reset.sh

# Build the same three layers as a tracked stack:
gh stack init                     # start on top of main
# ...add foundation content, git commit...
gh stack add feature              # next layer
# ...add feature content, git commit...
gh stack add cleanup              # top layer
# ...add cleanup content, git commit...

gh stack view                     # see the whole stack
gh stack submit                   # push + open all three PRs, correctly based
```

Now the payoff. A teammate lands on `main` again:

```bash
./demo/land-on-main.sh
```

Re-sync the **entire** stack with one command:

```bash
gh stack sync
```

That single command fetches `main`, cascades the rebase through every branch in
the right order, pushes each one, and updates PR state. No ordering to remember,
no repeated force-pushes.

### Bonus: editing a branch in the middle

The other daily pain — you fix something in a lower branch and everything above
is now stale:

```bash
gh stack down            # drop to the branch that needs the change
# ...edit, git commit...
gh stack rebase --upstack   # cascade the change into every branch above it
gh stack push
```

There is also a **"Rebase stack"** button in the PR merge box on github.com for
a server-side cascade. Note: use the CLI if your repo requires signed commits,
so signatures stay valid.

---

## Reset between rehearsals

```bash
./demo/reset.sh
```

Returns to `main` at the `demo-base` tag and deletes all `stack/*` branches.

## Verified commands

_Filled in after a real `gh stack` run against this repo so the live demo uses
exactly what works. (Pending `gh auth login`.)_
