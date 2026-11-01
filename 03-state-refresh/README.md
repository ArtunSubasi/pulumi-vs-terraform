# 03 — State + refresh

**Goal:** open the state file in both tools. Then show the one default that differs the
most: Terraform reads the real world before every plan, and Pulumi trusts its state unless
you ask it to refresh.
**Time:** 4 min.
**Live typing:** one `aws_s3_bucket` resource + output per tool. The rest is commands.
**Needs:** AWS credentials and `AWS_REGION` in both terminals. Open the S3 console in a browser
tab beforehand. Both buckets show up when you search for `state-refresh`.

| | Terraform | Pulumi |
|---|---|---|
| Where | `terraform.tfstate` (JSON) | `.pulumi-state/.pulumi/stacks/<project>/<stack>.json` (JSON checkpoint) |
| Look inside | `cat terraform.tfstate`, `terraform state list / show` | `pulumi stack export`, `pulumi stack --show-urns` |
| Identity | resource address `aws_s3_bucket.demo` | URN `urn:pulumi:dev::state-refresh::aws:s3/bucket:Bucket::pulumi-state-refresh` |
| Secrets in state | **clear text** (`"result": "7YAE…"`) | **encrypted** (`"ciphertext": "v1:…"`) |
| Refresh before plan | **yes, by default** | **no, by default** |
| Opt out / opt in | `-refresh=false` | `--refresh`, `pulumi refresh`, or `options: refresh: always` |
| Only reconcile state | `terraform apply -refresh-only` | `pulumi refresh` |

**The tamper step (both tools):** S3 console → the bucket → *Properties* → *Tags* → *Edit* →
change `env` from `dev` to `prod` → *Save changes*.

## Terraform (`terraform/live`)

```bash
cd 03-state-refresh/terraform/live
# LIVE: aws_s3_bucket "demo" + output
terraform apply -auto-approve  # bucket tf-state-refresh-<timestamp>
cat terraform.tfstate          # JSON, and look: "result": "<the password in clear text>"
terraform state list
terraform state show random_password.db     # result = (sensitive value). The CLI hides it, the file doesn't.

# TAMPER in the console: env = prod
terraform plan                 # "Refreshing state..." → ~ tags { ~ "env" = "prod" -> "dev" }, 1 to change
terraform plan -refresh=false  # No changes. (trusts the state, like Pulumi's default)
terraform plan -refresh-only   # "Objects have changed outside of Terraform": ~ tags { "env" = "dev" -> "prod" }
terraform apply -auto-approve  # sets env back to dev, in place
terraform destroy -auto-approve
```

An in-place diff, not a replacement: the bucket keeps its identity (its name), only an
attribute changed. Deleting the bucket in the console instead shows the other kind of drift:
"has been deleted" → 1 to add.

## Pulumi (`pulumi/live`)

```bash
cd 03-state-refresh/pulumi/live
pulumi stack init dev
# LIVE: new aws.s3.Bucket("pulumi-state-refresh", ...) + export
pulumi up --yes                # bucket pulumi-state-refresh-<7 random chars>
pulumi stack export            # JSON checkpoint; "result": { "ciphertext": "v1:..." }
pulumi stack --show-urns
ls .pulumi-state/.pulumi/stacks/state-refresh/

# TAMPER in the console: env = prod
pulumi preview                 # 3 unchanged ← doesn't ask AWS at all
pulumi preview --refresh       # refreshes first → ~ update [diff: ~tags,tagsAll]
pulumi refresh --yes           # updates the state only: tags.env is now "prod" in the checkpoint
pulumi up --yes                # code says dev → sets it back, in place
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
- **Pulumi's AWS provider is built from Terraform's.** `@pulumi/aws` wraps the
  `hashicorp/aws` provider through the Pulumi Terraform bridge, so both tools run the same
  `Read` code when they refresh. The diff (`tags`, `tagsAll` / `tags_all`) comes from the same
  schema. Deeper dive: 11.
- **Drift in AWS is cheap to create.** A tag edited in the console, a security group rule
  added during an incident, an autoscaler changing a count: the tool only finds out when
  it reads AWS. With Terraform that happens on every plan, with Pulumi only when asked.

## OpenTofu — good to know

- Same refresh semantics as Terraform (`-refresh=false`, `-refresh-only`).
- **Client-side state and plan encryption** (since 1.7) closes the "secrets in clear text"
  gap. See `06-secrets/opentofu`. Terraform 1.17 still has no equivalent.
