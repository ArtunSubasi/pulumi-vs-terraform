# 06 — Secrets

**Goal:** an API token passed in from outside plus a generated DB password, both written
to a `.env` file and combined into a connection string. Then follow the secrets: CLI
output, outputs, config files and state.
**Time:** 4 min.
**Live typing:** Terraform: the sensitive output (4 lines). Pulumi: reading the secret,
two derived outputs, one `pulumi.secret()` (5 lines).

| | Terraform | Pulumi |
|---|---|---|
| Input secret | `variable { sensitive = true }` + `TF_VAR_api_token` | `pulumi config set --secret apiToken` + `config.requireSecret()` |
| At rest in config | (not stored. You pass it on every run) | `Pulumi.dev.yaml`: `secure: v1:…` (encrypted with the stack passphrase / KMS) |
| Hidden in CLI | `(sensitive value)` | `[secret]` |
| Reveal | `terraform output -json` / `-raw` | `pulumi stack output --show-secrets` |
| **In state** | **clear text** | **encrypted** (`ciphertext`) |
| Derived values | sensitivity propagates through expressions | secretness propagates through `apply`, `interpolate`… |
| Never stored | `ephemeral` resources + write-only attributes (1.10/1.11) | (no direct equivalent: secrets are stored, encrypted) |

## Terraform (`terraform/live`)

```bash
cd 06-secrets/terraform/live
export TF_VAR_api_token='tok-s3cr3t-demo'
terraform init
# LIVE: output "connection_string" with sensitive = true
terraform apply -auto-approve       # connection_string = <sensitive>; ephemeral...: Opening/Closing
terraform output                    # <sensitive>
terraform output -json              # ...and there it is, in clear text
grep -n 's3cr3t' terraform.tfstate  # the token, inside local_sensitive_file's content
grep -n '"result"' terraform.tfstate
grep -c bootstrap terraform.tfstate # 0: the ephemeral password never reaches state
# Try: content = ephemeral.random_password.bootstrap.result →
#   Error: Invalid use of ephemeral value … not a write-only attribute
terraform destroy -auto-approve
```

## Pulumi (`pulumi/live`)

```bash
cd 06-secrets/pulumi/live
pulumi stack init dev
pulumi config set apiToken tok-s3cr3t-demo            # oops, forgot --secret…
pulumi preview                                        # → "must be encrypted as it's secret" (schema in Pulumi.yaml)
pulumi config set --secret apiToken tok-s3cr3t-demo
cat Pulumi.dev.yaml                                   # secure: v1:...
# LIVE: requireSecret, connectionString, tokenLength, adminUser
pulumi up --yes                                       # every output: [secret]
pulumi stack output --show-secrets
grep -c 's3cr3t' .pulumi-state/.pulumi/stacks/secrets/dev.json   # 0
pulumi stack export | grep -c ciphertext                         # encrypted values
cat out/.env                                          # the file itself is plain text, of course
pulumi destroy --yes && pulumi stack rm dev --yes
```

## OpenTofu (`opentofu/final`) — state encryption

```bash
cd 06-secrets/opentofu/final
export TF_VAR_state_passphrase='a long passphrase, 16+ chars'   # needed for EVERY command, init too
tofu init && tofu apply -auto-approve
head -c 300 terraform.tfstate       # {"meta":{"key_provider.pbkdf2.passphrase":…},"encrypted_data":"…"}
tofu output -raw password           # works, with the right passphrase
TF_VAR_state_passphrase='wrong passphrase 1234' tofu plan   # decryption failed … authentication failed
tofu destroy -auto-approve
```

`main.tofu` encrypts both the state and saved plans (`enforced = true` refuses to write
anything unencrypted). Migrating existing plaintext state needs a temporary `fallback`
block with `method "unencrypted"`. Key providers besides `pbkdf2`: AWS KMS, GCP KMS,
OpenBao, Azure Key Vault (1.11), external programs (1.10). The AWS KMS variant
(no passphrase at all) is showcase 07.

## Talking points

- **`sensitive` is a display flag, not encryption.** It hides values in plan/apply output
  and forces you to acknowledge sensitive outputs (02), but the state stores everything in
  clear text. Protecting state is up to the backend: an encrypted S3 bucket, IAM, no local
  copies.
- **Pulumi encrypts secrets before writing them**, both in config files and in state, with
  a per-stack key: a passphrase, Pulumi Cloud, or AWS KMS / Azure Key Vault / GCP KMS /
  Vault via `--secrets-provider`. Secretness propagates automatically, and you can mark
  any value with `pulumi.secret()`.
- **Terraform's answer is different: don't store it at all.** `ephemeral` resources and
  variables plus write-only attributes (`aws_ssm_parameter.value_wo`,
  `aws_db_instance.password_wo`, …) keep secrets out of state and plan entirely. That's
  stronger where it applies, but it only works with providers that offer write-only
  attributes. Comes back with AWS in Phase 2.
- **Both:** the moment a secret is written somewhere (here `.env`), it is plain text
  there. Both tools only protect their own records.

## OpenTofu — good to know

- **State and plan encryption** (since 1.7) — see above. Terraform 1.17 has none.
- **Ephemeral resources, variables, outputs and write-only attributes** since 1.11, same
  syntax as Terraform.
