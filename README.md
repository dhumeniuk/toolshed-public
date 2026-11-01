# toolshed-public

Public repo containing basic tools: the shared git hook scripts in
`scripts/` (secrets scan, commit message format, backlog item reference,
doc-only commits, release notes, roadmap).

## Using it from a repo

Install it as a pinned dev dependency, straight from GitHub (it isn't
published to the npm registry):

```bash
npm install --save-dev github:dhumeniuk/toolshed-public#v1.0.0
```

`package-lock.json` then records the exact commit, so local checkouts,
cloud sessions and CI all run the same scripts, and `npm install` / `npm ci`
is the only setup step — no separate clone, no `TOOLSHED_PUBLIC` env var.

Each script is a `bin`, named after the file without `.sh`. Call them from
`lefthook.yml` with `npx --no-install` (so a missing install fails fast
instead of prompting):

```yaml
pre-commit:
  commands:
    secrets:
      run: npx --no-install check-no-secrets

commit-msg:
  commands:
    format:
      run: npx --no-install check-commit-msg-format {1}
```

and from CI after `npm ci`, e.g. `npx --no-install check-no-secrets` with
`CI=true` (which `actions/*` runners already set).

| Command                   | Hook       | Checks                                                         |
| ------------------------- | ---------- | -------------------------------------------------------------- |
| `check-no-secrets`        | pre-commit | No `.env` files or secret-looking strings staged (all files in CI) |
| `check-commit-msg-format` | commit-msg | `<type>(<scope>): ([<id>]) <description>`                      |
| `check-backlog-item`      | commit-msg | A `[<id>]` reference unless the commit is `.md`-only           |
| `check-doc-commit-files`  | commit-msg | `doc:` commits touch only `.md` files                          |
| `check-release-notes`     | commit-msg | `RELEASE_NOTES.md` lists the referenced GitHub issue           |
| `check-desc-match`        | commit-msg | Commit description matches its `RELEASE_NOTES.md` row          |
| `check-roadmap`           | commit-msg | Referenced issue was removed from `ROADMAP.md`                 |

## Releasing a change

Commit to `main`, bump `version` in `package.json`, and tag it
(`git tag v1.1.0 && git push origin v1.1.0`). Consuming repos pick it up
by changing the `#v…` ref in their `package.json` and running
`npm install` — never automatically.
