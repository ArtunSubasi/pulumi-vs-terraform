# 02 — Hello world + the apply workflow

**Goal:** the same two resources in both tools, and one full change cycle:
plan/preview → apply/up → change an input → read the diff → destroy.
**Time:** 4 min (2 min per tool).
**Live typing:** one `random_password` resource and one output per tool.

| | Terraform | Pulumi |
|---|---|---|
| Resources | `random_pet`, `random_password` | `random.RandomPet`, `random.RandomPassword` |
| Input | `variable "prefix"` | `config.get("prefix")` |
| Show the plan | `terraform plan` | `pulumi preview` |
| Apply | `terraform apply` | `pulumi up` |
| Change the input | `-var prefix=prod` | `pulumi config set prefix prod` |
| Tear down | `terraform destroy` | `pulumi destroy` |

## Terraform (`terraform/live`)

```bash
cd 02-hello-world/terraform/live
terraform init                       # providers come from the offline mirror
# LIVE: type random_password "db" + output "password" (without `sensitive`)
terraform plan                       # Error: Output refers to sensitive values
# LIVE: add `sensitive = true`
terraform apply                      # review the plan, then type "yes"
terraform output                     # password = <sensitive>
terraform output -raw password       # ...but it's one command away (more in 06)
terraform plan -var prefix=prod      # random_pet.name must be replaced (-/+)
terraform apply -var prefix=prod -auto-approve
terraform destroy -auto-approve
```

## Pulumi (`pulumi/live`)

```bash
cd 02-hello-world/pulumi/live
pulumi stack init dev                # asks for the passphrase (see repo README)
# LIVE: type new random.RandomPassword("db", ...) + export const password
pulumi preview
pulumi up                            # choose "yes" in the prompt
pulumi stack output                  # password  [secret]
pulumi stack output password --show-secrets
pulumi config set prefix prod
pulumi preview --diff                # +- RandomPet (replace)
pulumi up --yes
pulumi destroy --yes
pulumi stack rm dev --yes
```

## Talking points

- **Same workflow, different words.** `plan`/`apply` ↔ `preview`/`up`. Both show a diff and
  ask before changing anything. Both mark a replacement explicitly: `-/+` and
  `must be replaced` in Terraform, `+-` and `(replace)` in Pulumi.
- **Inputs:** Terraform has typed `variable` blocks, set with `-var`, `*.tfvars` or `TF_VAR_*`.
  Pulumi reads stack config, set with `pulumi config set` and stored in `Pulumi.<stack>.yaml`.
  More in 05.
- **Secrets, first contact:** Terraform refuses to output a sensitive value unless you say
  `sensitive = true`. Pulumi marks `RandomPassword.result` as `[secret]` on its own, because
  the provider schema says so. More in 06.
- **Saved plans:** `terraform plan -out=tfplan` + `terraform apply tfplan` applies exactly
  what was reviewed. Pulumi's closest equivalents are still opt-in: `pulumi preview
  --save-plan` (marked `[PREVIEW]`) + `pulumi up --plan` (`[EXPERIMENTAL]`, hidden unless
  `PULUMI_EXPERIMENTAL=1`), or `pulumi up --strict` (`[EXPERIMENTAL]`, constrains the update
  to its own preview). By default `pulumi up` runs a fresh preview and asks.

## OpenTofu — good to know

The whole Terraform part works unchanged with `tofu init / plan / apply / destroy`.
