# Cheat sheet — the talk on one page

**Before:** `make reset-live && make prep && make check && make reset`. Then, in two
terminals (left Terraform, right Pulumi): `source scripts/env.sh` + `export PULUMI_CONFIG_PASSPHRASE=…`.
**Fallback for every step:** `cd ../final` — same code, finished.
**Watermark:** 30 min core. Backup blocks 08–12 only if there's time or interest.

| ⏱ | # | Terraform (left) | Pulumi (right) | Say |
|---|---|---|---|---|
| 0:00 | **01 Bootstrap** · 3′ | type `versions.tf` + `main.tf` → `terraform init` → `cat .terraform.lock.hcl` → `apply` | `pulumi new typescript --name bootstrap --dir live --generate-only --yes` → tour → `backend:` in Pulumi.yaml → `npm i @pulumi/random` → `stack init dev` → `up` | 2 files vs. a Node project. One dependency system vs. two (npm SDK + plugin). The state backend is a day-one choice in Pulumi |
| 0:03 | **02 Hello world** · 4′ | type `random_password` + output → error → `sensitive = true` → `apply` → `plan -var prefix=prod` → `destroy` | type `RandomPassword` + export → `up` → `[secret]` → `config set prefix prod` → `preview --diff` → `destroy` | Same workflow, different words. `-/+` vs. `+-`. Saved plans: TF built in, Pulumi experimental |
| 0:07 | **03 State + refresh** · 4′ | type `local_file` → `apply` → `cat terraform.tfstate` (password in clear!) → `echo tampered > out/app.conf` → `plan` ✔ drift → `plan -refresh=false` ✘ | type `local.File` → `up` → `stack export` (ciphertext) → tamper → `preview` ✘ → `preview --refresh` ✔ → `refresh` → `options: refresh: always` | **TF refreshes by default, Pulumi doesn't.** Pulumi's `local` *is* the TF provider (bridge) |
| 0:11 | **04 Abstraction** · 7′ | tour module + `for_each` → type `count = var.public ? 1 : 0` + `dynamic "source"` → `apply` → `state list` → `unzip -l out/bundle.zip` | tour `Service` class → type `JSON.stringify(...)` → `up` → `cat out/api.json` 💥 → fix with `pulumi.jsonStringify` → type `if (args.public)` → `up` | HCL special constructs vs. map/if/arrays. **`Output<T>` is the price.** Replacement order: Pulumi create-before-delete! |
| 0:18 | **05 Environments** · 4′ | `workspace new dev` → `apply -var-file=envs/dev.tfvars` → type `prod.tfvars` → `workspace new prod` → wrong var-file → type precondition → error | type config reads + loop → `stack init dev` → `up` → `stack init prod` → `config set instanceCount three` → schema error → `--type int … 3` → `up` | Workspaces ≠ environments (dir-per-env). Stacks are first-class. `stack rm` deletes the stack file → `--preserve-config` |
| 0:22 | **06 Secrets** · 4′ | `export TF_VAR_api_token=…` → type sensitive output → `apply` → `output -json` 😬 → `grep s3cr3t terraform.tfstate` → ephemeral not in state | `config set apiToken …` → `preview` → "must be encrypted" → `--secret` → type outputs → `up` → `[secret]` → `grep` state: 0 hits | `sensitive` = display flag. Pulumi encrypts at rest. TF's answer: ephemeral + write-only (never stored). OpenTofu: state encryption (`06-secrets/opentofu`) |
| 0:26 | **07 Testing** · 5′ | `cat tests/service.tftest.hcl` → `terraform test` → type `run "rejects_uppercase_name"` → `test` | `cat service.test.ts` → `npm test` → type `it("rejects uppercase names")` → `npm test` | Both have mocks now. Built-in declarative vs. your own toolchain. Gotcha: TF runs share state |
| 0:31 | **Q&A / backup** | 08 remote backend · 09 drift deep-dive · 10 providers & licensing · 11 refactoring (`moved` vs. `aliases`) · 12 ESC / Automation API | | |

## Neutral one-liners (when asked "which one?")

- **Terraform:** one declarative language, plan-first workflow, refresh by default, huge
  ecosystem and hiring pool. Limits: HCL expressiveness, secrets in plain-text state.
- **Pulumi:** real languages (types, tests, IDE, packages), secrets encrypted by default,
  stacks as a first-class concept. Limits: `Output<T>` learning curve, more moving parts
  (runtime, npm, plugins), no refresh by default.
- **OpenTofu:** drop-in Terraform fork (MPL). Adds state encryption, provider `for_each`,
  `-exclude`, `enabled`, early evaluation. Diverging since 1.6.

## If something breaks

| Symptom | Fix |
|---|---|
| `terraform init` wants network | `source scripts/env.sh` (sets `TF_CLI_CONFIG_FILE` to the mirror) |
| `Inconsistent dependency lock file` | someone ran `tofu` in a Terraform dir → `git checkout -- .terraform.lock.hcl && terraform init` |
| Pulumi asks for a passphrase repeatedly | `export PULUMI_CONFIG_PASSPHRASE=…` |
| `stack 'dev' already exists` | `pulumi stack select dev` (or `make reset ONLY=NN`) |
| `pulumi new`: directory not empty | `rm -rf live` in `01-bootstrap/pulumi` (or `make reset-live ONLY=01`) |
| Typed code is a mess | `cd ../final` and carry on |
