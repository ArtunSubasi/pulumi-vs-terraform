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

## OpenTofu "good to know" (to verify per showcase while building)

| Showcase | OpenTofu difference |
|---|---|
| 01 | `tofu init`, OpenTofu registry, `.tofu` file extension overrides `.tf` |
| 03 / 06 / 08 | **Client-side state & plan encryption** (since 1.7) — closes the "secrets in plain-text state" gap that Pulumi already covers |
| 04 | Provider `for_each` (1.9), `-exclude` flag (1.9), `enabled` meta-argument (verify version) |
| 05 / 08 | Early variable evaluation: variables in `backend` blocks and module `source` (1.8) — makes per-environment backends simpler |
| 07 | `tofu test` with mocks — compare feature parity with `terraform test` |

To check: Terraform 1.17 may have closed some of these gaps. Each claim will be
verified against the installed versions (Terraform 1.17.0, OpenTofu 1.13.2,
Pulumi 3.271.0) before it goes into a README.

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
- [ ] **Blocked:** sandbox egress proxy filters the Terraform/OpenTofu registries and Pulumi plugin downloads (see below)
- [ ] Repo skeleton, Makefile, `CHEATSHEET.md`
- [ ] Showcases 01–07 (final + live), verified offline
- [ ] Backup blocks 09–11 (offline-capable parts)
- [ ] Phase 2: switch hello-world/state/secrets/backends to real AWS

## Sandbox blockers

The agent sandbox's egress proxy currently rejects these hosts (`Filtered` / HTTP 403),
so providers and plugins can't be installed and nothing can be verified yet:

- `registry.terraform.io`: Terraform provider registry
- `releases.hashicorp.com`: `hashicorp/*` provider binaries
- `registry.opentofu.org`: OpenTofu provider registry
- `get.pulumi.com`: Pulumi resource plugin binaries
- `api.pulumi.com`: Pulumi template listing for `pulumi new <name>`. Optional: `pulumi new https://github.com/pulumi/templates/tree/master/typescript` works without it

## Handover notes (for the next session)

### Environment facts (verified 2026-10-22)

- Sandbox: Terraform 1.17.0, OpenTofu 1.13.2, Pulumi 3.271.0, Node v24.22.1, npm 11.19.1, linux_arm64.
- The memory limit is 8 GiB (cgroup). `/workspace` is on disk. `$PULUMI_HOME=/workspace/.af-deps/pulumi`,
  `$TMPDIR=/workspace/.af-tmp`. LocalStack (fallback only) is at `host.containers.internal:4566`.
- Egress: npm and github.com work. The registries listed under "Sandbox blockers" were blocked. The operator
  was asked to add them to `policies/network-allowlist.conf` (tinyproxy filter, one host pattern per line).
  **First step of the next session:** re-test with
  `terraform init` on a scratch project using `hashicorp/random`, and `pulumi plugin install resource random`.
  If a download redirects to another blocked host, report that exact hostname and wait. Don't work around the proxy.
- `pulumi new typescript` (by name) needs `api.pulumi.com`. The GitHub URL form works already:
  `pulumi new https://github.com/pulumi/templates/tree/master/typescript --name <n> --generate-only --yes`.
  It generates `Pulumi.yaml` (runtime nodejs, packagemanager npm), `package.json` (`@pulumi/pulumi`,
  `typescript`, `@types/node`), `tsconfig.json` (strict, nodenext), `index.ts`, `.gitignore` (`/bin/`, `/node_modules/`).
  On the speaker's laptop the short form should work. `--offline` uses cached templates (for `prep.sh`).
- The repo has only `README.md` (empty) and `PLAN.md`. Branch `agent/initial-setup`. Nothing committed beyond
  the initial commit. Pushing is disabled, and the operator merges on the host.

### Repo conventions decided

- Top level: `PLAN.md`, `README.md` (how to use the repo), `CHEATSHEET.md` (talk on one page),
  `Makefile` (`prep`, `reset`, `check`), `scripts/prep.sh`, `.gitignore`.
- `.gitignore` must cover `*.tfstate*`, `.terraform/`, `terraform.tfstate.d/`, `node_modules/`, `bin/`,
  `.pulumi-state/` (or whatever the local Pulumi backend dir is), `.idea/`, `*.tfplan`, generated files
  from `local_file`, and the provider mirror / cache dir.
- Commit `.terraform.lock.hcl` and `package-lock.json` (reproducible + offline `npm ci`).
- Never commit a `Pulumi.<stack>.yaml` that contains `encryptionsalt` or `secure:` values (passphrase-bound).
  Stack config with plain values only. Secrets are set via commands in the README or Makefile.
- Blank markers: `# LIVE: <hint>` (HCL) and `// LIVE: <hint>` (TS). `live/` must still parse or compile where
  feasible, or at least fail obviously. Check that `diff -r final live` stays small (5–10 lines per tool).
- Every showcase `README.md` contains: goal, time budget, step-by-step commands for both tools, talking
  points, the neutral comparison, and an "OpenTofu — good to know" box where relevant.

### Implementation ideas per showcase (to validate while building)

- **Pulumi local backend per project:** try `backend: url: file://<relative dir>` in `Pulumi.yaml` so the
  state sits next to the code like `terraform.tfstate` (nice for 03). If relative paths don't work, use
  `PULUMI_BACKEND_URL` set by the Makefile, or `pulumi login --local`. Stacks are then
  `organization/<project>/<stack>`.
- **Same provider on both sides for refresh/drift (03, 09):** Terraform `hashicorp/local` `local_file`.
  For Pulumi, try `pulumi package add terraform-provider hashicorp/local` (any-Terraform-provider bridge,
  generates a local SDK under `sdks/`). That's also a talking point for the providers block. Fallback: a small
  TypeScript dynamic provider that writes a file and implements `read`.
  Demo: create the file → edit or delete it by hand → `terraform plan` detects it (refresh by default)
  vs. `pulumi preview` shows no changes → `pulumi preview --refresh` / `pulumi refresh` detects it. Check
  whether Pulumi 3.271 has a project/stack option or env var to refresh by default
  (`options.refresh: always` in `Pulumi.yaml`, `PULUMI_REFRESH`?), and whether the default changed recently.
- **02 hello world:** `random_pet` + `random_password`. Changing `length` / `prefix` shows replacement in both diffs.
- **03 state:** `random_password.result` is clear text in `terraform.tfstate`. Pulumi marks
  `RandomPassword.result` as secret automatically → ciphertext in state.
- **04 abstraction (offline):** a "services" map → per service `random_password` + `local_file` (rendered
  JSON config). Terraform: local module + `for_each` + conditional `count`. Pulumi: `ComponentResource`
  class with a typed args interface, loop, `if`, and the `Output<T>` / `pulumi.interpolate` pitfall.
  `dynamic` blocks need a resource with nested blocks. That probably waits for the AWS phase (e.g. security
  group rules). Offline candidate: `tls_cert_request` `subject` (weak).
- **05 environments:** Terraform `.tfvars` per environment + workspaces (`terraform.workspace`,
  `terraform.tfstate.d/`). Mention directory-per-environment in the README. Pulumi stacks `dev` / `prod` with
  committed plain `Pulumi.dev.yaml` / `Pulumi.prod.yaml`, `pulumi config`, a `StackReference` mention.
  **Check:** does `pulumi stack init` write `encryptionsalt` into an existing committed stack file? If
  yes, either accept a dirty working tree and let `make reset` restore it, or create stack files via script.
- **06 secrets:** Terraform `sensitive` variable/output, `terraform output -json` reveals it, state is clear text.
  `ephemeral "random_password"` (random provider ≥ 3.7) is not stored in state; the real consumer
  (write-only attribute such as `aws_ssm_parameter.value_wo`) comes in the AWS phase. Pulumi
  `pulumi config set --secret`, `config.requireSecret`, `secure:` in stack file, encrypted state,
  `pulumi stack output --show-secrets`, secretness propagation through `interpolate`.
  OpenTofu extra: an `encryption.tofu` with a `pbkdf2` key provider whose passphrase comes from a
  variable (shows state encryption + early evaluation). The passphrase must not be committed.
- **07 testing:** Terraform module with a `validation` block + `tests/*.tftest.hcl` (`command = plan`,
  `mock_provider`, `expect_failures`). Pulumi: vitest + `pulumi.runtime.setMocks`, testing component
  outputs and a validation error. Live: write one `run` block / one `it(...)`.
- **prep.sh:** `terraform providers mirror` into a repo-local, git-ignored mirror dir + an offline
  `.tfrc` (`provider_installation { filesystem_mirror {...} }`) used via `TF_CLI_CONFIG_FILE` on stage.
  Same for OpenTofu if `*.tofu` examples exist. `npm ci` + `pulumi install` in every Pulumi project
  (fetches plugins). Pre-run `pulumi new` once so `--offline` works. Then run `terraform init` in every
  Terraform project.
- **JetBrains IDEA Ultimate:** list the needed plugins in `README.md` (Terraform and HCL plugin, Node.js /
  TypeScript support). Don't commit `.idea/`.

### OpenTofu / Terraform claims still to verify against installed versions

State and plan encryption (OpenTofu 1.7+), early variable evaluation in `backend` / module `source`
(OpenTofu 1.8), provider `for_each` and `-exclude` (OpenTofu 1.9), `enabled` meta-argument (version?),
`.tofu` extension precedence, `tofu test` mock parity, Terraform ephemeral resources (1.10) and
write-only attributes (1.11), Terraform S3 backend `use_lockfile` (1.10+). Also check what Terraform
1.12–1.17 added that might close or open gaps. That's newer than the agent's knowledge cutoff, so read the changelogs.

### Next steps (in order)

1. Confirm the proxy allowlist works (see above).
2. Build the skeleton: `.gitignore`, `README.md`, `Makefile`, `scripts/prep.sh`, `CHEATSHEET.md` stub.
3. Build showcases 01–07: `final/` first and verify each end to end offline (apply, destroy, tests),
   then derive `live/` from it.
4. Backup blocks 09–11 (offline-capable parts).
5. Phase 2 (when the AWS sandbox account exists): ask the operator for short-lived credentials
   (SSO device code or exported session env vars). Move hello-world / state / secrets / backends to AWS,
   and add `dynamic` blocks + write-only attributes.
