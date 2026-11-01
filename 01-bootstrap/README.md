# 01 — Bootstrap

**Goal:** what a new project looks like on day one. Terraform starts from two hand-written
files. Pulumi starts from a generator and a Node.js project.
**Time:** 3 min (1.5 min per tool).
**Live typing:** Terraform: `versions.tf` + `main.tf` (~12 lines). Pulumi: `pulumi new`, two
lines of `backend:` and one resource.

| | Terraform | Pulumi |
|---|---|---|
| Create | write `versions.tf` + `main.tf` by hand | `pulumi new typescript` |
| Project file | `terraform { required_providers {…} }` block | `Pulumi.yaml` |
| Dependencies | providers, pinned in `.terraform.lock.hcl` | npm packages in `package.json` + `package-lock.json`, plus provider plugins |
| Download | `terraform init` → `.terraform/` | `npm install` → `node_modules/`; plugins → `~/.pulumi/plugins` |
| Environment | (default) workspace | stack `dev` → `Pulumi.dev.yaml` |
| State | `terraform.tfstate` (local backend by default) | backend chosen at login or in `Pulumi.yaml` (here: `./.pulumi-state`) |

## Terraform (`terraform/live`)

```bash
cd 01-bootstrap/terraform/live
# LIVE: versions.tf — terraform { required_version, required_providers { random } }
# LIVE: main.tf — resource "random_pet" "server" + output
terraform init                 # downloads the provider, writes .terraform.lock.hcl
ls -a; cat .terraform.lock.hcl
terraform apply -auto-approve
terraform destroy -auto-approve
```

`final/` has the same two files plus a committed lock file with hashes for five platforms
(`terraform providers lock -platform=…`).

**Mirror vs. registry:** with `source scripts/env.sh`, `init` installs from the offline mirror
and prints `(unauthenticated)` plus a warning that the lock file only has checksums for
this platform. With network, `unset TF_CLI_CONFIG_FILE` first: you get
`(signed by HashiCorp)` and the full hashes. The difference is a talking point in itself:
the lock file is the supply-chain record.

## Pulumi (`pulumi/live` — doesn't exist yet, `pulumi new` creates it)

```bash
cd 01-bootstrap/pulumi
pulumi new typescript --name bootstrap --dir live --generate-only --yes   # add --offline without network
cd live
ls -a                          # Pulumi.yaml, package.json, tsconfig.json, index.ts, .gitignore
cat Pulumi.yaml                # name, runtime: nodejs, packagemanager: npm
# LIVE: append to Pulumi.yaml:
#   backend:
#     url: file://./.pulumi-state
mkdir .pulumi-state
npm install --prefer-offline
npm install --prefer-offline @pulumi/random
# LIVE: index.ts — new random.RandomPet("server", { length: 2 }) + export
pulumi stack init dev          # passphrase prompt → Pulumi.dev.yaml gets an encryptionsalt
pulumi up --yes
pulumi destroy --yes
```

### Optional beat: "Where does the state go?" (~1 min)

Before typing the `backend:` lines, ask the CLI where it would write. This shows the lookup
order `PULUMI_BACKEND_URL` → `backend.url` in `Pulumi.yaml` → machine-wide `pulumi login`.
Precondition: no machine-wide login (`pulumi logout`), and no `PULUMI_BACKEND_URL` in the shell.

```bash
pulumi stack init dev          # → Pulumi Cloud login prompt. Ctrl-C.
                               #   No backend pinned, no login → Pulumi Cloud is the default.

# Option A — machine-wide: works, but it's the trap from the talking points below
pulumi login --local           # file://~ → state in ~/.pulumi/stacks/bootstrap/dev.json
pulumi whoami -v               # Backend URL: file://~
pulumi logout                  # undo, or every other project on this laptop uses it too

# Option B — per project (what the rest of the demo uses)
# LIVE: append backend: url: file://./.pulumi-state to Pulumi.yaml (see above), mkdir .pulumi-state
pulumi whoami -v               # Backend URL: file://./.pulumi-state
pulumi stack init dev          # passphrase prompt, no login
```

Where Option A puts the state (verified, 3.271), after `stack init` / `up`:

```
~/.pulumi/meta.yaml                         # backend layout version (project-scoped stacks)
~/.pulumi/stacks/bootstrap/dev.json         # the state
~/.pulumi/stacks/bootstrap/dev.json.bak     # previous version, rewritten on every save
~/.pulumi/stacks/bootstrap/*.attrs          # metadata from the storage library
~/.pulumi/history/bootstrap/dev/…           # one checkpoint per update (after the first `up`)
```

`~` here is the OS user's home directory from the user database. Setting `$HOME` or
`$PULUMI_HOME` does not move it (`$PULUMI_HOME` only moves `credentials.json`, plugins and
templates). To put the state elsewhere, use `pulumi login file:///some/dir` or `backend.url`.
`pulumi new` itself has no backend flag. `PULUMI_BACKEND_URL=… pulumi new …` creates the stack
there, but doesn't write it into `Pulumi.yaml`, so the variable has to stay set.

Point to make: A and B both give "local state", but A stores the decision on the *machine*,
B in the *repo*. With A still logged in, B still wins because `backend.url` beats the login.
Skip B and whatever login the laptop happens to have decides: that's the incident below.

Without `--generate-only`, `pulumi new` also runs `npm install` and creates the stack in one
go. That's faster, but it needs the backend to be decided first, either by a `pulumi login`
or with `PULUMI_BACKEND_URL`.

`make reset-live` deletes `pulumi/live` again.

## Talking points

- **Zero to one:** Terraform needs no generator. Two small files are a complete project.
  Pulumi's starting point is a real Node.js project, with `package.json`, a compiler config
  and ~200 npm packages. Unfamiliar for ops people, but home turf for developers.
- **Two dependency systems in Pulumi:** the npm package (`@pulumi/random`) is the typed SDK.
  The provider plugin (`pulumi-resource-random`) is a separate binary, fetched on first use
  or with `pulumi install`. Terraform has one: the provider binary.
- **Lock files:** `.terraform.lock.hcl` pins providers by version and hash.
  `package-lock.json` pins the SDKs, and the SDK version decides the plugin version.
- **State backend is a day-one decision in Pulumi — and if you don't make it, the machine
  makes it for you.** Pulumi picks the backend in this order (verified, 3.271):
  `PULUMI_BACKEND_URL` → `backend.url` in `Pulumi.yaml` → whatever `pulumi login` was last
  run on this machine (`~/.pulumi/credentials.json`). `pulumi new` only asks you to log in
  when there is no login at all. Terraform defaults to a local file, and a remote backend
  is a `backend` block you write into each project (09).
  - **Real incident from preparing this talk:** `pulumi new` → `stack init` → `up` went
    through without a single question. The state didn't land locally or in Pulumi Cloud,
    but in an `azblob://…-prod` container of an unrelated project, the last thing
    the CLI had been logged into. No Azure env vars were set and no PIM role was active.
    It still worked: Pulumi's Azure backend falls back to the Azure CLI's cached refresh
    token (`~/.azure/`, valid for weeks), and the user held a *permanent* `Storage Blob
    Data Contributor` assignment, which PIM never covered (PIM `Contributor` is control
    plane only, so blob access had been requested separately). A `pulumi destroy` in the
    wrong directory would have hit the same container.
  - **The login is global, the project is local.** `pulumi login` is machine-wide state,
    invisible in the repo. Two terminals, two projects, one current backend. `pulumi whoami -v`
    shows where you're about to write.
  - **Mitigations:** pin `backend.url` in every `Pulumi.yaml` (as this repo does) or set
    `PULUMI_BACKEND_URL` per directory (`direnv`). `pulumi logout` / `az logout` when you
    switch projects. Make data-plane roles on state storage PIM-eligible, not permanent.
  - **Coding agents:** with no login at all, Pulumi 3.271 detects an AI agent (e.g. Claude
    Code) and silently signs up an *ephemeral Pulumi Cloud account* (`/tmp/.pulumi`,
    claimable for 30 days) instead of failing. Yet another place state could end up.
  - Terraform isn't immune: the `azurerm`/`s3` backends use the same cached CLI
    credentials. But *where* state goes is written in the project, not in the machine.
- **Stacks need a passphrase** with any non-Cloud backend, because Pulumi encrypts secrets
  in config and state from the first command. More in 06.

## OpenTofu — good to know

- `tofu init` uses `registry.opentofu.org`, so the lock file records
  `registry.opentofu.org/hashicorp/random` instead of `registry.terraform.io/…`.
  Use separate directories (or re-`init`) when switching tools.
- `*.tofu` files are read only by OpenTofu, and `main.tofu` overrides a `main.tf` with the
  same base name (since 1.8). That's how one directory can serve both tools.
