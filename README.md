# github-stacks-demo

A tiny project used to demonstrate **GitHub Stacks** (native stacked pull requests) to the team,
using GitHub's own tooling — the [`gh stack`](https://gh.io/stacks) CLI extension and the stack UI
on github.com.

The code is a deliberately small **component library** (`src/`). The point of the repo is the
_workflow_: how a change that naturally splits into dependent layers — a multi-phase migration —
is built, reviewed, and, the part that actually hurts today, **rebased** when `main` moves or a
lower layer changes.

## The sample library

`src/` exposes a `createComponent()` factory over shared design `tokens`. The demo migrates its
API from a legacy positional string to a validated options object across **4 phases**, each a PR
stacked on the one below:

1. **foundation** — options-object API alongside the legacy string
2. **variants** — resolve variants to a full style object
3. **validate** — option validation and shared defaults
4. **cleanup** — drop the legacy positional API

## The demo

See [`demo/RUNBOOK.md`](demo/RUNBOOK.md) for the full 5-minute walkthrough.

```bash
demo/setup.sh   # build the stack + PRs and a teammate PR to merge live
demo/reset.sh   # tear it all down to a clean slate between rehearsals
```

Everything the scripts create lives under `demo/scenario/` as plain per-phase file snapshots, so
the migration is easy to read and the demo is fully repeatable.

> Requires the [`gh stack`](https://github.com/github/gh-stack) extension:
> `gh extension install github/gh-stack`.
