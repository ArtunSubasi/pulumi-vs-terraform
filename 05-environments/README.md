# 05 — Environments

**Goal:** one codebase, two environments (`dev`: 1 instance, debug logging; `prod`:
3 instances), each with its own state.
**Time:** 4 min.
**Live typing:** Terraform: `envs/prod.tfvars` + a precondition (8 lines). Pulumi: reading
config + a loop (5 lines). `Pulumi.prod.yaml` is created by commands.

| | Terraform | Pulumi |
|---|---|---|
| Unit of environment | workspace (`terraform workspace new prod`) — or a directory per environment | stack (`pulumi stack init prod`) |
| Values | `envs/<env>.tfvars`, passed with `-var-file` **on every command** | `Pulumi.<stack>.yaml`, picked automatically for the selected stack |
| Set a value | edit the `.tfvars` | `pulumi config set [--type int] key value` |
| Name in code | `terraform.workspace` | `pulumi.getStack()` |
| Typing | `variable` `type =` + `validation` | `config:` schema in `Pulumi.yaml` (+ `requireNumber` …) |
| State | `terraform.tfstate.d/<workspace>/` | one checkpoint per stack |
| Cross-env reads | `terraform_remote_state` data source | `new pulumi.StackReference("org/project/stack")` |

## Terraform (`terraform/live`)

```bash
cd 05-environments/terraform/live
terraform init
terraform workspace new dev
terraform apply -var-file=envs/dev.tfvars -auto-approve
# LIVE: envs/prod.tfvars
terraform workspace new prod
terraform plan -var-file=envs/dev.tfvars     # the classic mistake: dev values in the prod workspace…
# LIVE: the precondition in main.tf
terraform plan -var-file=envs/dev.tfvars     # → Error: Resource precondition failed
terraform apply -var-file=envs/prod.tfvars -auto-approve
ls terraform.tfstate.d/ out/
terraform workspace list
# clean up: destroy in each workspace (with its var-file), then
terraform workspace select default && terraform workspace delete -force dev && terraform workspace delete -force prod
```

## Pulumi (`pulumi/live`)

```bash
cd 05-environments/pulumi/live
cat Pulumi.yaml Pulumi.dev.yaml    # schema + committed dev values (plain, no secrets)
# LIVE: index.ts — config.requireNumber("instanceCount"), config.require("logLevel"), the loop
pulumi stack init dev && pulumi up --yes
pulumi stack init prod
pulumi config set instanceCount three        # wrong type…
pulumi preview                               # → must be of type 'integer' (checked before the program runs)
pulumi config set --type int instanceCount 3
cat Pulumi.prod.yaml
pulumi up --yes
pulumi stack ls
# clean up (keep the committed stack files!):
pulumi destroy --yes -s prod && pulumi stack rm prod --yes --preserve-config
pulumi destroy --yes -s dev  && pulumi stack rm dev  --yes --preserve-config
```

`make reset` restores the committed `Pulumi.dev.yaml` (`stack init` adds an
`encryptionsalt` to it) and deletes the uncommitted `Pulumi.prod.yaml` in `live/`.

## Talking points

- **Workspaces are not environments.** HashiCorp's own docs say CLI workspaces are not a
  good fit for strongly separated environments: same backend, same credentials, and
  nothing stops `prod` values in the `dev` workspace (hence the precondition). Many teams
  use **a directory per environment** that calls shared modules instead (more files, but
  explicit), or a wrapper like Terragrunt.
- **Stacks are first-class in Pulumi:** config is bound to the stack, so no `-var-file` to
  forget. The stack file is committed (minus secrets), so a code review shows what differs
  between environments.
- **Pulumi gotchas:** `pulumi stack init` writes an `encryptionsalt` into the stack file,
  and `pulumi stack rm` **deletes** the stack file unless you add `--preserve-config`.
- **Cross-environment / cross-project data:** `StackReference` reads another stack's
  outputs, and secrets stay secret. Terraform's `terraform_remote_state` needs read access
  to the whole remote state file.

## OpenTofu — good to know

- **Early evaluation (1.8):** variables and locals in `backend` blocks and module
  `source`. A per-environment backend can be
  `backend "s3" { key = "${var.env}/terraform.tfstate" }`, so one directory serves all
  environments without workspaces or `-backend-config` files. Terraform 1.17 still rejects
  variables in `backend`. It allows them in module `source`/`version` since 1.15, but only
  with `const = true` variables.
