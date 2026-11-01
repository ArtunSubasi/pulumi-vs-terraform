# 07 — Cloud encryption

**Goal:** the secrets from 06 again, but the key comes from AWS KMS instead of a passphrase.
Pulumi and OpenTofu only. Plain Terraform has no client-side state encryption.
**Time:** 3 min.
**Live typing:** OpenTofu: the `aws_kms` key provider + `keys =` (6 lines). Pulumi: two
exports (2 lines). The KMS part itself is one flag on `pulumi stack init`.
**Needs:** an AWS login. Region: `eu-central-1`. It's pinned in `main.tofu`, because OpenTofu's
key provider ignores the region in your AWS profile.

| | OpenTofu | Pulumi |
|---|---|---|
| Configured in | `encryption` block in the code (or `TF_ENCRYPTION`) | per stack: `pulumi stack init --secrets-provider awskms://…` |
| Stored where | `key_provider.aws_kms…` in the state file's `meta` | `secretsprovider:` + `encryptedkey:` in `Pulumi.<stack>.yaml` |
| What gets encrypted | the **whole** state file, plus saved plans | only **secret values**, in state and stack config |
| KMS calls | `GenerateDataKey` (write), `Decrypt` (read) | `Encrypt` once at stack init, `Decrypt` per command |
| Change the key | `fallback` block: read with old, write with new | `pulumi stack change-secrets-provider` |
| Terraform | — (only backend-side, e.g. S3 SSE-KMS) | |

## Setup (once)

```bash
cd 07-cloud-encryption
export AWS_REGION=eu-central-1          # for the aws CLI and the Pulumi commands below
aws sts get-caller-identity             # logged in?
./key.sh create                         # KMS key + alias/tf-vs-pulumi-demo
# Key ARN:  arn:aws:kms:eu-central-1:123456789012:key/1234abcd-…
# Pulumi:   pulumi stack init dev --secrets-provider "awskms:///arn:aws:kms:…?region=eu-central-1"
```

Both URL forms work for Pulumi: the ARN form printed by `key.sh` (three slashes) and
the alias form used below. The ARN is unambiguous, because it stays valid if the alias is
moved to another key and it names the account. The alias is easier to read on stage.

## OpenTofu (`opentofu/live`)

```bash
cd 07-cloud-encryption/opentofu/live
cat ../../../06-secrets/opentofu/final/main.tofu | grep -A3 key_provider   # 06: passphrase
# LIVE: key_provider "aws_kms" "demo" { kms_key_id, region, key_spec } + keys = key_provider.aws_kms.demo
tofu init                               # no TF_VAR_state_passphrase anymore
tofu apply -auto-approve
head -c 300 terraform.tfstate           # {"meta":{"key_provider.aws_kms.demo":"…"},"encrypted_data":"…"}
tofu output -raw password               # decrypts through KMS, with your IAM identity
AWS_PROFILE=nobody tofu plan            # no credentials → no state (any identity without kms:Decrypt fails the same way)
tofu destroy -auto-approve
```

## Pulumi (`pulumi/live`)

```bash
cd 07-cloud-encryption/pulumi/live
unset PULUMI_CONFIG_PASSPHRASE          # prove that no passphrase is involved
pulumi stack init dev --secrets-provider "awskms://alias/tf-vs-pulumi-demo?region=$AWS_REGION"
cat Pulumi.dev.yaml                     # secretsprovider: awskms://…  encryptedkey: …  (no encryptionsalt)
pulumi config set --secret apiToken tok-s3cr3t-demo
cat Pulumi.dev.yaml                     # secure: v1:…
# LIVE: export password + tokenLength
pulumi up --yes
pulumi stack output --show-secrets
pulumi stack export | grep -c ciphertext
pulumi destroy --yes && pulumi stack rm dev --yes
```

`NoCredentialProviders: no valid providers in chain. Deprecated.` means you're on an older
Pulumi CLI that uses AWS SDK for Go **v1**. It can't use `aws login` or SSO sessions.
Pulumi 3.271 uses SDK v2 and finds them. Upgrade, or hand over temporary credentials
explicitly: `eval "$(aws configure export-credentials --format env)"`.

Switching an existing passphrase stack (e.g. 06) over to KMS:
`pulumi stack change-secrets-provider "awskms://alias/tf-vs-pulumi-demo?region=$AWS_REGION"`.
Pulumi re-encrypts the stack config and state with the new key.

## Clean up

```bash
./key.sh delete                         # alias gone, key deleted after 7 days (destroy both projects first!)
```

## Talking points

- **No shared secret anymore.** With a passphrase, everyone on the team (and CI) needs the
  same string. With KMS, access is IAM on the key: grant `kms:Decrypt` (+
  `GenerateDataKey` / `Encrypt`) per role, revoke it any time, and every decrypt appears in
  CloudTrail.
- **Envelope encryption in both:** KMS never sees the state. It only encrypts a data key,
  and that encrypted data key is stored next to the data (state `meta` / stack file
  `encryptedkey`).
- **Different scope:** OpenTofu encrypts the whole state, so resource names, IDs and tags are
  hidden too. Pulumi encrypts only values marked secret. The rest of the checkpoint stays
  readable JSON, which is good for diffs and debugging, but it's also visible to anyone who
  can read the backend.
- **Different binding:** Pulumi stores the provider per stack, so `dev` and `prod` can use
  different keys (or even different clouds) with no code change. In OpenTofu it's part of
  the code. One key per environment means a variable in `kms_key_id` (early evaluation,
  1.8) or a directory per environment (see 05 `env-per-directory`).
- **Chicken and egg:** the key must exist before the first encrypted state. Here a script
  creates it, and in real setups a separate "bootstrap" or platform project does.
- **Deleting the key deletes the state**, in effect: anything encrypted with it can't be
  read anymore. KMS enforces a 7–30 day waiting period, so a mistake can still be undone
  (`aws kms cancel-key-deletion`).
- **Terraform:** no client-side encryption. Use an S3 backend with SSE-KMS and a tight
  bucket policy. That protects the state at rest in S3, but not a local copy or `terraform
  state pull`.
