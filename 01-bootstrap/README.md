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
- **State backend is a day-one decision in Pulumi.** `pulumi new` asks you to log in: to
  Pulumi Cloud by default, or with `pulumi login --local` / `file://` / `s3://`. Terraform
  defaults to a local file and you opt into a remote backend later (08).
- **Stacks need a passphrase** with any non-Cloud backend, because Pulumi encrypts secrets
  in config and state from the first command. More in 06.

## OpenTofu — good to know

- `tofu init` uses `registry.opentofu.org`, so the lock file records
  `registry.opentofu.org/hashicorp/random` instead of `registry.terraform.io/…`.
  Use separate directories (or re-`init`) when switching tools.
- `*.tofu` files are read only by OpenTofu, and `main.tofu` overrides a `main.tf` with the
  same base name (since 1.8). That's how one directory can serve both tools.
