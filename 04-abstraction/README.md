# 04 — Abstraction & complexity

**Goal:** the same reusable building block in both tools: per service, a generated DB
password, a JSON config file, a TLS key for public services only, and one zip bundling all
configs. Then compare how loops, conditionals, nested blocks and reuse are expressed.
**Time:** 7 min (the longest core block, and the one with the most audience questions).
**Live typing:** Terraform: the `dynamic` block + the `count` conditional (8 lines).
Pulumi: the config JSON (pitfall first, then the fix) + the `if` (9 lines).

| Concept | Terraform | Pulumi (TypeScript) |
|---|---|---|
| Reuse | local module `modules/service` | `class Service extends pulumi.ComponentResource` |
| Interface | `variable` blocks | `interface ServiceArgs` (checked by the compiler, with IDE autocomplete) |
| Loop | `for_each = var.services` | `Object.entries(services).map(...)` |
| Conditional resource | `count = var.public ? 1 : 0`, then `[0]` | `if (args.public) { ... }` |
| Nested blocks from data | `dynamic "source" { for_each … content { … } }` | an array: `sources: deployed.map(...)` |
| Serialize | `jsonencode()` — values are known or unknown | `pulumi.jsonStringify()` — **not** `JSON.stringify()` |
| Addresses | `module.service["api"].local_file.config` | URN `…::demo:index:Service$local:index/file:File::api-config` |

## Terraform (`terraform/live`)

```bash
cd 04-abstraction/terraform/live
# Tour: main.tf (variable "services", module for_each, archive_file), modules/service/main.tf
# LIVE: modules/service/main.tf — count = var.public ? 1 : 0
# LIVE: main.tf — dynamic "source" { for_each = module.service ... }
terraform init                 # local modules get installed too
terraform apply -auto-approve
terraform state list           # module.service["api"].tls_private_key.this[0], ...
unzip -l out/bundle.zip
terraform destroy -auto-approve
```

## Pulumi (`pulumi/live`)

```bash
cd 04-abstraction/pulumi/live
pulumi stack init dev
# Tour: service.ts (ComponentResource, typed args), index.ts (loop, archive)
# LIVE: service.ts — this.config = JSON.stringify({ ..., db_password: db.result })
#       It compiles. Wrap it as pulumi.output(JSON.stringify(...)) for the type.
pulumi up --yes
cat out/api.json               # "db_password": "Calling [toJSON] on an [Output<T>] is not supported..."
# LIVE: fix → pulumi.jsonStringify({ ... })
# LIVE: if (args.public) { new tls.PrivateKey(...) }
pulumi up --yes
cat out/api.json               # the real password
pulumi stack --show-urns       # parent/child tree under demo:index:Service
pulumi destroy --yes && pulumi stack rm dev --yes
```

## Talking points

- **Expressiveness:** HCL has loops (`for_each`, `for`), conditionals (`count`, ternaries)
  and `dynamic` blocks. They're powerful, but each is a special construct with its own
  rules (`count` → `[0]` indexing, `dynamic` → the iterator is named after the block).
  In TypeScript these are just `map`, `if` and arrays, plus classes, functions, unit tests,
  npm packages and the IDE.
- **The catch is `Output<T>`.** Values that are only known after a resource is created
  (IDs, generated passwords) are promises with dependency tracking. You can't
  `JSON.stringify` them, concatenate them with `+` or use them in an `if`. You use
  `.apply()`, `pulumi.interpolate` or `pulumi.jsonStringify`. The compiler doesn't catch the
  mistake here: it silently writes a warning string into the file. Terraform has the same
  concept (an "unknown value" during plan), but the language handles it for you.
- **Secretness propagates.** The archive invoke gets secret inputs (the passwords), so its
  whole result is secret: `pulumi stack output bundlePath` shows `[secret]`. Safe, but
  sometimes surprising (`pulumi.unsecret()` if you're sure).
- **Replacement order differs!** Pulumi replaces **create-before-delete** by default (no
  gap without the resource). Terraform does **destroy-before-create** (`-/+`) unless you set
  `lifecycle { create_before_destroy = true }` (`+/-`).
  - **Why Pulumi can afford it: auto-naming.** Without an explicit name, a cloud resource
    gets its logical name plus a random suffix (`my-bucket-a1b2c3d`: "-" + 7 random chars),
    so old and new never collide.
  - **Explicit names are handled too, for bridged providers.** If you set an auto-named
    field like `bucket` yourself, the Terraform bridge switches that resource to
    delete-before-replace on its own (`nameRequiresDeleteBeforeReplace` in
    pulumi-terraform-bridge).
  - **The gap: unique fields that aren't auto-named.** `local.File.filename` is one, as are
    DNS record names, ports and file paths. Pulumi's default writes the new file, then
    deletes it as "the old one". Hence `deleteBeforeReplace: true` in `service.ts`.
  - **Terraform has the mirror image.** Its default is safe for fixed names, but
    `create_before_destroy` with a fixed name hits the same collision: verified with
    `local_file`, which is gone after the replace. The usual fix is a `name_prefix`
    argument (AWS) or a `random_id` suffix. Terraform has no auto-naming: an omitted name
    is up to the provider (e.g. `aws_s3_bucket` → `terraform-2026…`).
- **Complexity cuts both ways:** HCL caps how clever a config can get. TypeScript doesn't,
  so the team's discipline (code review, tests in 07) sets the limit.

## OpenTofu — good to know

- **Provider `for_each`** (1.9): one provider configuration per region or account, selected
  with `provider = aws.by_region[each.key]`. Terraform 1.17 rejects `for_each` in a
  provider block. Gotcha: the provider instance must outlive its resources by one apply.
- **`lifecycle { enabled = var.x }`** (1.11): a conditional resource without `count`, so no
  `[0]` index in addresses. Terraform 1.17 doesn't have it.
- **`-exclude=ADDRESS`** (1.9) is the inverse of `-target`. Not in Terraform 1.17.
- **Variables in module `source`:** OpenTofu since 1.8. Terraform since 1.15, but only for
  variables marked `const = true`.
