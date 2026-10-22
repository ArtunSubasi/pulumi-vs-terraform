# 03 — State + refresh

**Goal:** open the state file in both tools. Then show the one default that differs the
most: Terraform reads the real world before every plan, and Pulumi trusts its state unless
you ask it to refresh.
**Time:** 4 min.
**Live typing:** one `local_file` resource + output per tool. The rest is commands.

| | Terraform | Pulumi |
|---|---|---|
| Where | `terraform.tfstate` (JSON) | `.pulumi-state/.pulumi/stacks/<project>/<stack>.json` (JSON checkpoint) |
| Look inside | `cat terraform.tfstate`, `terraform state list / show` | `pulumi stack export`, `pulumi stack --show-urns` |
| Identity | resource address `local_file.config` | URN `urn:pulumi:dev::state-refresh::local:index/file:File::config` |
| Secrets in state | **clear text** (`"result": "7YAE…"`) | **encrypted** (`"ciphertext": "v1:…"`) |
| Refresh before plan | **yes, by default** | **no, by default** |
| Opt out / opt in | `-refresh=false` | `--refresh`, `pulumi refresh`, or `options: refresh: always` |
| Only reconcile state | `terraform apply -refresh-only` | `pulumi refresh` |

## Terraform (`terraform/live`)

```bash
cd 03-state-refresh/terraform/live
# LIVE: local_file "config" + output
terraform apply -auto-approve
cat terraform.tfstate          # JSON, and look: "result": "<the password in clear text>"
terraform state list
terraform state show random_password.db     # result = (sensitive value). The CLI hides it, the file doesn't.

echo tampered > out/app.conf                # drift: change it behind Terraform's back
terraform plan                 # "Refreshing state..." → Plan: 1 to add
terraform plan -refresh=false  # No changes. (trusts the state, like Pulumi's default)
terraform plan -refresh-only   # "Objects have changed outside of Terraform: local_file.config has been deleted"
terraform apply -auto-approve  # puts the file back
terraform destroy -auto-approve
```

Why "deleted" and not "changed"? `local_file`'s ID is a hash of its content, so a file with
different content counts as a different object. Real cloud resources usually show an
in-place diff (see 09 on AWS).

## Pulumi (`pulumi/live`)

```bash
cd 03-state-refresh/pulumi/live
pulumi stack init dev
# LIVE: new local.File("config", ...) + export
pulumi up --yes
pulumi stack export            # JSON checkpoint; "result": { "ciphertext": "v1:..." }
pulumi stack --show-urns
ls .pulumi-state/.pulumi/stacks/state-refresh/

echo tampered > out/app.conf
pulumi preview                 # 3 unchanged ← doesn't look at the file at all
pulumi preview --refresh       # local:index:File config refresh → + 1 to create
pulumi refresh --yes           # updates the state only: config deleted
pulumi up --yes                # recreates it
# Make it the default for this project: uncomment `options: refresh: always` in Pulumi.yaml
pulumi preview                 # now shows "refreshing" for every resource
pulumi destroy --yes && pulumi stack rm dev --yes
```

## Talking points

- **State is the tool's memory in both:** what exists, its IDs and its last known
  attributes. Both are JSON, both can be inspected, and both must never be edited by hand
  (`terraform state mv/rm`, `pulumi state rename/move/remove`).
- **Secrets:** Terraform's state holds every attribute in clear text, even values the CLI
  shows as `(sensitive value)`. Pulumi encrypts every secret value (here with the stack
  passphrase) before it's written. Teaser for 06.
- **Refresh, the main point.** Terraform calls every provider's `Read` before planning, so a
  plan always reflects reality. That costs time and API calls on big states (hence
  `-refresh=false`, and `-minimal-refresh` new in 1.17). Pulumi plans against the last
  checkpoint, which is fast, but drift stays invisible until you `--refresh` or
  `pulumi refresh`. You can flip the default per project (`options: refresh: always` in
  `Pulumi.yaml`) or per shell (`PULUMI_OPTION_REFRESH=true`).
- **The `local` provider in Pulumi is the Terraform provider.** `pulumi package add
  terraform-provider hashicorp/local 2.9.1` generated a typed TypeScript SDK under `sdks/`
  (git-ignored, recreated by `pulumi install`). Deeper dive: 10.

## OpenTofu — good to know

- Same refresh semantics as Terraform (`-refresh=false`, `-refresh-only`).
- **Client-side state and plan encryption** (since 1.7) closes the "secrets in clear text"
  gap. See `06-secrets/opentofu`. Terraform 1.17 still has no equivalent.
