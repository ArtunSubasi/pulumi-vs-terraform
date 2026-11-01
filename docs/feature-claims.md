# Feature claims — verified

Checked on **2026-10-22** against **Terraform 1.17.0** and **OpenTofu 1.13.2** (linux_arm64):
changelogs (hashicorp/terraform, opentofu/opentofu, terraform-provider-aws) plus small
scratch configs run with both binaries. Re-check before the talk if the versions change.

| Claim | Verdict | Since | Evidence / nuance |
|---|---|---|---|
| OpenTofu client-side state + plan encryption | ✅ OpenTofu only | Tofu 1.7 | Tested (`06-secrets/opentofu`): state = `{"meta":…,"encrypted_data":…}`, wrong passphrase → `authentication failed`. `enforced = true` exists. pbkdf2 passphrase ≥ 16 chars. `init` needs the passphrase too |
| Terraform state encryption | ❌ none in 1.12–1.17 | — | No changelog entry. Terraform's route is ephemeral values + write-only attributes |
| Variables in `backend` blocks | ✅ OpenTofu only | Tofu 1.8 | TF 1.17: `Variables not allowed` |
| Variables in module `source` / `version` | ✅ both, with a catch | Tofu 1.8 · TF 1.15 | Terraform requires the variable to be `const = true` ("Only literal values and const variables can be evaluated during init") |
| Provider `for_each` | ✅ OpenTofu only | Tofu 1.9 | TF 1.17: `Reserved argument name in provider block`. Gotcha: provider instance must outlive its resources by one apply |
| `-exclude` flag | ✅ OpenTofu only | Tofu 1.9 (`-exclude-file` 1.10) | TF 1.17: `Failed to parse command-line flags` |
| `enabled` meta-argument | ✅ OpenTofu only, as `lifecycle { enabled = … }` | Tofu 1.11 | Address has no `[0]`. A bare reference to a disabled resource is null, so guard it. TF 1.17 rejects it |
| `.tofu` overrides same-named `.tf` | ✅ | Tofu 1.8 | Terraform ignores `*.tofu` entirely |
| Test framework parity (`mock_provider`, `override_resource`, `override_data`, `expect_failures`, `command = plan`) | ✅ | TF 1.6/1.7 · Tofu 1.6/1.8 | `08-testing` passes 4/4 on both. Divergence since: TF 1.17 mocks for ephemeral resources; Tofu 1.11 `for_each` in `mock_provider` |
| Ephemeral resources, `ephemeral "random_password"` | ✅ both | TF 1.10 · Tofu 1.11 · hashicorp/random 3.7.0 | Not in state (tested). Using it in a normal argument → `Invalid use of ephemeral value` |
| Write-only attributes | ✅ both | TF 1.11 · Tofu 1.11 | AWS: `aws_ssm_parameter.value_wo`, `aws_rds_cluster.master_password_wo` (provider 5.87), `aws_db_instance.password_wo`, `aws_secretsmanager_secret_version.secret_string_wo` (5.88). Each with `*_wo_version`. No offline provider has any |
| S3 backend `use_lockfile` | ✅ both | TF 1.10 (GA 1.11) · Tofu 1.10 | TF 1.11 deprecated `dynamodb_table` (warning at `init`). Tofu 1.13.2 gives no deprecation warning |
| `terraform plan` refreshes by default | ✅ | — | `-refresh=false`, `-refresh-only`. **New in 1.17:** `-minimal-refresh` |
| Pulumi: no refresh by default | ✅ | — | Tested (03). Opt in: `--refresh`, `pulumi refresh`, `options: refresh: always` in `Pulumi.yaml`, or `PULUMI_OPTION_REFRESH=true` (`always` only works in `Pulumi.yaml`) |
| Pulumi update plans | ⚠️ opt-in | — | `preview --save-plan` is `[PREVIEW]`. `up --plan` is `[EXPERIMENTAL]` and hidden without `PULUMI_EXPERIMENTAL=1`. `up --strict` is `[EXPERIMENTAL]` |
| Pulumi replacement order | ✅ create-before-delete by default | — | Tested (04): a `local.File` with a fixed name disappears on replace. Fix: `deleteBeforeReplace: true`. Auto-naming (name + "-" + 7 random chars) normally prevents collisions. For an explicitly set auto-named field, bridged providers switch to delete-before-replace automatically (source: pulumi-terraform-bridge `nameRequiresDeleteBeforeReplace`; not run against AWS) |
| Terraform replacement order | ✅ destroy-before-create by default | — | Tested: `lifecycle { create_before_destroy = true }` + a fixed `local_file` name → the file is gone after the replace (the deposed object's destroy deletes it). Fix: `name_prefix` / `random_id` suffix |

## Terraform 1.12 → 1.17 highlights

- **1.12:** `terraform test` parallelism. `import` blocks with resource `identity`. Short-circuiting logical operators.
- **1.13:** `terraform stacks` CLI. Variable definitions in test files.
- **1.14:** list resources (`*.tfquery.hcl`) + `terraform query` (can generate import config). `action` blocks.
- **1.15:** variables/locals in module `source`/`version` (with `const`). `deprecated` on variables/outputs. `convert()`. `validate` checks `backend` blocks.
- **1.16:** `terraform_data` `store` block for ephemeral/sensitive values. `import` blocks in modules. `lifecycle { destroy = false }`. `graph -format=mermaid`.
- **1.17** (2026-10-21): variables/locals in provider requirements. `-minimal-refresh`. Terraform Policy GA (`-policies`). Mocks for ephemeral resources.

**Gaps that remain vs. OpenTofu in 1.17:** state encryption, variables in `backend`,
provider `for_each`, `-exclude`, `enabled`.

## Not verified at runtime (changelog only)

Write-only attributes (needs AWS, Phase 2), S3 locking against real S3, variables in
`required_providers` (TF 1.17), the `terraform_data` `store` block, `terraform query`,
actions.
