# Terraform vs. Pulumi: 100% Code, 0% Slides — Demo Plan

Working plan for the demo repository. Everything in English.

## Constraints

- **Slot:** 45 min including Q&A. **Core demo: ~30 min (watermark).** Everything
  beyond that is a backup block, swapped in or out depending on audience interest.
- **Tools:** Terraform (primary) vs. Pulumi with **TypeScript**. OpenTofu appears as
  "good to know" call-outs wherever it differs in a relevant way.
- **Target:**
  - **Phase 1 (now):** offline providers only (`random`, `tls`, `local`, `time`,
    `terraform_data` / `@pulumi/random`, `@pulumi/tls`, `@pulumi/command`).
  - **Phase 2:** real AWS once the sandbox account exists. LocalStack is only a fallback.
- **State:** local backends by default. Remote backends are a separate showcase,
  either backup or live, depending on the audience.
- **Structure:** every showcase is an isolated, self-contained project, so a failure
  can't cascade and you can jump to any of them.
- **IDE:** JetBrains IntelliJ IDEA Ultimate.
- **Tone:** neutral. The code shows the trade-offs, and any verdict is given verbally.

## Two versions per showcase

```
NN-topic/
  README.md            # talking points, commands, time budget, OpenTofu "good to know"
  terraform/
    final/             # ready to run — prep + cheat sheet
    live/              # 60–90% done, blanks marked with  # LIVE: <hint>
  pulumi/
    final/
    live/              # blanks marked with  // LIVE: <hint>
```

- **Size of the blanks:** each `live/` gap should be about 5–10 lines per tool per
  showcase, so it can be typed in about 2 minutes.
- **Verify by diff:** `diff -r final live` shows exactly what will be typed live.
- **Helpers:** a top-level `Makefile` handles `reset` (wipes state and
  `.terraform/`), `prep` (`init` / `npm ci` / plugin install for all showcases,
  so nothing gets downloaded on stage) and `check` (runs every `final/`).
- **`CHEATSHEET.md`:** the whole talk on one page — order, commands and talking points.

## Showcases

### Core (~30 min)

| # | Showcase | Terraform | Pulumi (TS) | Min |
|---|---|---|---|---|
| 01 | **Bootstrap** | Hand-written `versions.tf` + `main.tf`, `terraform init`, lock file | `pulumi new typescript`, tour of `Pulumi.yaml`, `package.json`, stack file, `node_modules` | 3 |
| 02 | **Hello world + apply workflow** | `random_pet` + `random_password`: `plan` → `apply` → change input → diff → `destroy` | The same resources: `preview` → `up` → diff → `destroy` | 4 |
| 03 | **State + refresh** | Open `terraform.tfstate`: JSON, secrets in clear text, `state list/show`. **Refresh on every plan/apply by default** (`-refresh=false`, `-refresh-only`) | `pulumi stack export`, URNs, checkpoint file. **No refresh by default** on `preview`/`up` — `pulumi refresh` / `--refresh` | 4 |
| 04 | **Abstraction & complexity** | `for_each`, conditionals via `count`, `dynamic` blocks, a local module | Loops, `if`, functions, a `ComponentResource` class, types + autocomplete. Catch: `Output<T>` / `apply()` | 7 |
| 05 | **Environments** | `.tfvars` per environment, workspaces vs. directory-per-environment | Stacks, `Pulumi.<stack>.yaml`, `pulumi config`, stack references | 4 |
| 06 | **Secrets** | `sensitive = true` hides output but not state. Ephemeral values / write-only attributes | `config set --secret`, encrypted in config **and** state, `pulumi.secret()`, secretness propagates | 4 |
| 07 | **Testing** | `terraform test`, `.tftest.hcl`, `mock_provider` | Unit tests with `pulumi.runtime.setMocks` + vitest | 5 |

**Sum: ~31 min**

### Backup blocks (swap in dynamically)

| # | Showcase | Notes |
|---|---|---|
| 08 | **Remote backend** | Terraform S3 backend with native locking (`use_lockfile`) vs. `pulumi login s3://…`. Blocked until AWS is available; LocalStack fallback |
| 09 | **Drift & refresh deep-dive** | Change a resource outside the tool, then compare both tools' default behaviour. Best on AWS (edit a tag in the console). Offline variant: `local_file` |
| 10 | **Providers & licensing** | BSL vs. MPL (OpenTofu) vs. Apache 2.0 (Pulumi). Pulumi's bridged providers (`@pulumi/random` *is* the Terraform provider underneath) vs. native providers. `tofu` as a drop-in |
| 11 | **Refactoring** | `moved` blocks vs. Pulumi `aliases`. `import` blocks vs. `pulumi import` |
| 12 | **Pulumi ESC / Automation API** | Only if Pulumi Cloud is acceptable — environments + secrets as a service. Automation API = IaC embedded in a program |

## OpenTofu "good to know" (verified, see [`docs/feature-claims.md`](docs/feature-claims.md))

| Showcase | OpenTofu difference |
|---|---|
| 01 | `tofu init` uses `registry.opentofu.org` (different lock file entries). `main.tofu` overrides `main.tf` (1.8) |
| 03 / 06 / 08 | **Client-side state & plan encryption** (1.7). Terraform 1.17 has none. Example: `06-secrets/opentofu` |
| 04 | Provider `for_each` (1.9), `-exclude` (1.9), `lifecycle { enabled = … }` (1.11) — none of them in Terraform 1.17 |
| 05 / 08 | Variables in `backend` blocks (1.8; Terraform 1.17: no). Module `source` variables: Tofu 1.8, Terraform 1.15+ only with `const = true` |
| 07 | `tofu test` runs `07-testing`'s tests unchanged, 4/4 |

## Decisions log

| Question | Decision |
|---|---|
| Target cloud | Offline providers first → real AWS later. LocalStack only as fallback |
| Pulumi language | TypeScript |
| Pulumi backend | Local file backend. Remote as a showcase step |
| Terraform backend | Local. Remote as a showcase step |
| Project structure | Isolated project per showcase |
| Licensing / OpenTofu | "Good to know" call-outs per showcase + backup block 10 |
| Language | English |
| IDE | JetBrains IntelliJ IDEA Ultimate |
| Tone | Neutral |
| Must-have topic | Default refresh behaviour (showcase 03, deep-dive 09) |
| Time | 30 min core as watermark, rest as swappable backup |

## Decisions (round 2)

| Question | Decision |
|---|---|
| Pulumi passphrase | Never committed. READMEs say: enter it interactively when prompted, or `export PULUMI_CONFIG_PASSPHRASE=...` in your own shell. Consequence: no `Pulumi.<stack>.yaml` with `encryptionsalt` / `secure:` values is committed — stacks and secrets are created by commands listed in the README / Makefile |
| Pulumi tooling | npm + vitest |
| Offline readiness | `scripts/prep.sh` pre-caches everything: Terraform/OpenTofu provider mirror (+ CLI config for offline `init`), `npm ci` and Pulumi plugins for every project, cached Pulumi template |
| OpenTofu in code | Code is Terraform-only. OpenTofu appears in READMEs, plus dedicated `*.tofu` examples only for OpenTofu-only features (e.g. state encryption) |

## Status

- [x] Plan agreed (this file)
- [x] Open questions answered
- [x] Sandbox egress allowlist fixed (2026-10-22): Terraform + OpenTofu registries, `releases.hashicorp.com`,
      `get.pulumi.com` and `api.pulumi.com` all work now
- [x] Repo skeleton: `.gitignore`, `README.md`, `Makefile`, `scripts/` (`prep`, `reset`, `check`, `diff`, `env.sh`), `CHEATSHEET.md`
- [x] Showcases 01–07 (final + live), verified offline: `reset → prep → check` passes for every `final/`
      (apply, idempotency re-plan/preview, `terraform test` / vitest, destroy), on Terraform 1.17.0,
      OpenTofu 1.13.2 (06 encryption example) and Pulumi 3.271.0
- [x] OpenTofu/Terraform claims verified → [`docs/feature-claims.md`](docs/feature-claims.md)
- [ ] Rehearsal on the speaker's laptop (`make reset-live prep check`, then a dry run with the live/ dirs)
- [ ] Backup blocks 09–11 (offline-capable parts)
- [ ] Phase 2: switch hello-world/state/secrets/backends to real AWS
  - [ ] 03 moved to an S3 bucket + console tag edit (local_file drift showed as "deleted", confusing). Written
    offline, **not run yet**: needs `terraform providers lock` (5 platforms) + `npm install` on the host, then a run against AWS

## Handover notes (for the next session)

### Environment facts (verified 2026-10-22)

- Sandbox: Terraform 1.17.0, OpenTofu 1.13.2, Pulumi 3.271.0, Node v24.22.1, npm 11.19.1, linux_arm64.
  Memory limit 8 GiB (cgroup). `/workspace` is on disk (virtiofs). `$PULUMI_HOME=/workspace/.af-deps/pulumi`,
  `$TMPDIR=/workspace/.af-tmp`. LocalStack (fallback only) is at `host.containers.internal:4566`.
- Egress: everything needed so far works (registries, provider downloads, Pulumi plugins + templates, npm, GitHub,
  raw.githubusercontent.com).
- **Sandbox quirk — Pulumi needs `TMPDIR=/tmp` here.** The Node.js language host creates FIFOs in `$TMPDIR`,
  and virtiofs (`/workspace`) refuses `mkfifo` → every `pulumi preview/up` fails with a bare
  `an unhandled error occurred: permission denied`. Run Pulumi commands (and `scripts/check.sh`) with
  `TMPDIR=/tmp` in the sandbox. FIFOs cost no memory. Not an issue on a normal laptop, so nothing in the repo
  works around it. Operator: worth fixing in the image (e.g. a `$TMPDIR` that supports FIFOs).
- **Sandbox image lacks `make`, `rsync`, `strace`, `strings`.** Run `scripts/*.sh` directly instead of `make`.
  The Makefile is a thin wrapper for the speaker's laptop.

### What was built — design notes

- **Offline provider mirror:** `scripts/prep.sh` runs `terraform providers mirror` (and `tofu providers mirror`)
  into **one** dir `.cache/provider-mirror` (layout `<registry host>/<ns>/<type>`, so both registries coexist) and
  writes `.cache/cli.tfrc`. `scripts/env.sh` exports `TF_CLI_CONFIG_FILE` — OpenTofu reads that variable too
  (a separate `TOFU_CLI_CONFIG_FILE` was ignored in favour of it). `providers mirror` needs `terraform get` first
  when there are local modules. From the mirror, `init` prints `(unauthenticated)` + an incomplete-lock warning
  (talking point in 01).
- **Lock files** are committed with hashes for 5 platforms (`terraform providers lock -platform=…`).
- **Pulumi state** per project: `backend: url: file://./.pulumi-state` in `Pulumi.yaml` works with a relative path,
  but the directory must exist → `.pulumi-state/.gitkeep` is committed. `.gitignore` needs `**/.pulumi-state/*`
  (a pattern with a slash is otherwise anchored to the repo root — that almost committed state once).
- **Same `local` provider on both sides:** `pulumi package add terraform-provider hashicorp/local 2.9.1` (and
  `hashicorp/archive 2.8.1` in 04) works offline after prep. It adds `packages:` to `Pulumi.yaml` and
  `"@pulumi/local": "file:sdks/local"` + `allowScripts` to `package.json`. `sdks/` is git-ignored because
  `pulumi install` regenerates it (prep does that). Projects with `file:sdks/` deps use `pulumi install`, the others
  `npm ci` + `pulumi install --no-dependencies`.
- **Pulumi refresh by default:** `options: refresh: always` in `Pulumi.yaml` works. So does
  `PULUMI_OPTION_REFRESH=true` (the value `always` does *not* work in the env var). 03 has it commented out.
- **Pulumi stack files:** `pulumi stack init` adds `encryptionsalt` to an existing committed stack file, and
  `pulumi stack rm` *deletes* the stack file unless `--preserve-config`. Hence: `reset.sh` restores tracked stack
  files via git and deletes untracked ones only if they contain a salt/secret. `check.sh` backs up and restores
  stack files itself.
- **Pulumi config schema** (`config:` in `Pulumi.yaml`): a wrong type, or a plaintext value for a `secret: true`
  key, is rejected at `preview`/`up` before the program runs. `pulumi config set` itself accepts it. Used in 05/06.
- **01 Pulumi live** has no committed dir: `pulumi new` refuses a non-empty target, so the speaker runs
  `pulumi new typescript --name bootstrap --dir live` from `01-bootstrap/pulumi`. `reset --live` deletes it. Prep
  rehearses that flow once in a temp dir so the template (`--offline`) and its npm deps (`--prefer-offline`) are cached.
  Fully offline rehearsal (`npm install --offline`) passed.
- **Findings that became talking points:**
  - Pulumi replaces **create-before-delete** by default. A `local.File` with a fixed name vanished on replace →
    `deleteBeforeReplace: true` (04). Pulumi normally avoids the collision through auto-naming (logical name +
    "-" + 7 random chars). And for an explicitly set auto-named field (e.g. `bucket`), the Terraform bridge flips
    the resource to delete-before-replace itself (`nameRequiresDeleteBeforeReplace`, pulumi-terraform-bridge
    `pkg/tfbridge/schema.go`). Unique fields that aren't auto-named (`filename`, DNS names…) get no such help.
    Terraform mirror image (verified): default destroy-before-create is safe, but `create_before_destroy` +
    fixed `filename` deletes the file just the same → `name_prefix` / `random_id` suffix.
  - `JSON.stringify` on an `Output<T>` compiles fine and silently writes
    `"Calling [toJSON] on an [Output<T>] is not supported…"` into the file (04 live moment).
  - Secretness propagates through invokes: 04's `bundlePath` output becomes `[secret]`.
  - `terraform test`: `run` blocks share state, so a per-run `override_resource` was ignored on a resource created
    by an earlier run → a file-level override (07).
  - **Pulumi backend selection** (01, verified 3.271): `PULUMI_BACKEND_URL` > `backend.url` in `Pulumi.yaml` >
    stored login. A `pulumi new` without a pinned backend silently wrote demo state into another project's prod
    `azblob://` container (cached `az` refresh token + permanent blob data role outside PIM). With no login and an
    AI agent detected, Pulumi signs up an ephemeral Pulumi Cloud account (`/tmp/.pulumi/agent-claim.json`).
    `pulumi login --local` = `file://~` → `~/.pulumi/stacks/<project>/<stack>.json`, where `~` is the OS user's home
    (ignores `$HOME`/`$PULUMI_HOME`). `pulumi new` has no backend flag and never writes `backend.url`.
  - Pulumi + vitest: a static import of the component is fine as long as the module creates no resources at import time.
- **Live gaps (`scripts/diff.sh`):** 02: TF 8 / Pulumi 5 lines, 03: 4/5, 04: 8/9, 05: 8/5, 06: 4/5, 07: 9/3.
  01 is a whole-project bootstrap by design.

### Next steps (in order)

1. Operator: review and merge `agent/initial-setup`. Rehearse on the speaker's laptop (macOS? → lock files already
   carry darwin hashes): `make reset-live prep check`, then one dry run per showcase from `live/` with a timer.
   Adjust the time budgets in the READMEs + `CHEATSHEET.md`.
2. Backup blocks (offline parts):
   - **09 drift deep-dive:** `local_file` + `local.File` (bridged), compare `plan` / `-refresh-only` / `pulumi refresh`
     / `options.refresh: always`, plus out-of-band *deletion* vs. *modification*.
   - **10 providers & licensing:** the `terraform-provider` bridge from 03/04 as the hook. `@pulumi/random` vs.
     `pulumi package add terraform-provider hashicorp/random`. BSL / MPL / Apache 2.0. `tofu` as a drop-in.
   - **11 refactoring:** `moved` blocks vs. Pulumi `aliases`. `import` blocks (+ TF 1.14 `terraform query`) vs. `pulumi import`.
3. Phase 2 (when the AWS sandbox account exists): ask the operator for short-lived credentials (SSO device code or
   exported session env vars). Move hello-world / state / secrets / backends to AWS. Add `dynamic` blocks with
   security group rules, write-only attributes (`aws_ssm_parameter.value_wo`) for 06, S3 backend with `use_lockfile`
   for 08, and drift via a console tag edit for 09.
