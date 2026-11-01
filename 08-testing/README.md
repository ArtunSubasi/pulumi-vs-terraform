# 08 — Testing

**Goal:** unit-test the same service contract in both tools. The config contains name +
port, the connection string uses the generated password, and invalid input is rejected.
No real resources, no network, a few seconds per run.
**Time:** 5 min.
**Live typing:** one negative test per tool: Terraform `run` block (9 lines), vitest
`it(...)` (3 lines).

| | Terraform | Pulumi (TypeScript) |
|---|---|---|
| Framework | built in: `terraform test`, `tests/*.tftest.hcl` | any test runner — here vitest (`npm test`) |
| Fake providers | `mock_provider "random" {}` | `pulumi.runtime.setMocks({ newResource, call })` |
| Pin a value | `override_resource { target, values }` | return it from `newResource` in the mock |
| Plan-only test | `command = plan` | (n/a — the mocks are the plan) |
| Validation | `variable { validation {...} }` | plain code: `throw new Error(...)` in the constructor |
| Expect an error | `expect_failures = [var.port]` | `expect(() => new Service(...)).toThrow()` |
| Assertions | `assert { condition, error_message }` | `expect(...)`, everything vitest/Jest offers |
| Read a value | direct: `local_file.config.content` | unwrap `Output<T>` with `.apply()` (helper `valueOf`) |

## Terraform (`terraform/live`)

```bash
cd 08-testing/terraform/live
cat tests/service.tftest.hcl     # mock_provider, override_resource, run blocks
terraform init
terraform test                   # 3 passed
# LIVE: run "rejects_uppercase_name" { command = plan, variables { name = "Billing" }, expect_failures = [var.name] }
terraform test                   # 4 passed
# Show a failure: change the validation to `var.port >= 10` → "Missing expected failure"
```

## Pulumi (`pulumi/live`)

```bash
cd 08-testing/pulumi/live
cat service.test.ts              # setMocks, valueOf, describe/it
npm test                         # 3 passed (vitest)
# LIVE: it("rejects uppercase names", () => expect(() => new Service("Billing", { port: 9000 })).toThrow(/lowercase/))
npm test                         # 4 passed
npx vitest                       # watch mode: tests re-run on save, nice in the IDE
```

## What a mocked unit test actually tests

With mocked providers, nothing talks to an API. The test exercises **your code**: the logic
that turns inputs into resource arguments and outputs. The provider's behaviour is not tested.

| Covered | Not covered |
|---|---|
| Input validation (`validation` blocks / `throw`) | Whether the cloud API accepts the arguments (limits, formats, quotas) |
| Expressions, string building, `jsonencode`, conditionals, loops | Defaults and computed values the real provider fills in |
| Wiring: which resource gets which value from which other resource | IAM permissions, networking, eventual consistency, name collisions |
| Outputs and their sensitivity / secretness | Update behaviour: in-place vs. replace, `create_before_destroy` |
| Which resources exist (Pulumi: with which options and parents) | Drift, and whether the deployed thing actually works |

In this showcase:

- `config_has_name_and_port` / "writes name and port": `name` and `port` end up in the
  JSON and the file name. That is `jsonencode` / `jsonStringify` plus string interpolation.
- `connection_string_uses_password`: the password resource's result is wired into the
  output. The value is pinned (`override_resource` / the `newResource` mock), because the
  real one would be random.
- `rejects_*`: the validation rules. Pure logic, no resource involved.

How the two mocks differ:

- **Terraform** still loads the real provider's **schema** (hence `terraform init`). Your
  configuration is type-checked against it, and the mock fills every computed attribute
  with generated fake data (e.g. random strings) unless you override it. The provider
  itself never runs.
- **Pulumi** mocks replace the engine *and* the provider. No plugin, no schema check at
  runtime: `newResource` gets the inputs and returns whatever state you want. Only
  TypeScript's compile-time types stand between you and a wrong argument. In exchange,
  you control every output exactly, and a test takes milliseconds.

So a green unit test means "my module computes what I intended", not "this will deploy".
That needs the layers below.

## Beyond unit tests

| Layer | Terraform | Pulumi |
|---|---|---|
| Static analysis | `tflint`, Checkov, Trivy (formerly tfsec), KICS | ESLint / `tsc`. Most IaC scanners don't read Pulumi programs |
| Policy on the plan | Terraform Policy (`-policies`, GA in 1.17), Sentinel, Conftest/OPA on `terraform show -json` | CrossGuard policy packs (`pulumi preview --policy-pack`), OPA/Rego supported |
| Integration (real infra) | `terraform test` with real providers and `command = apply`, or **Terratest** (Go: apply, probe from outside, destroy). `check` blocks for continuous assertions | Automation API in your test runner, or Go `integration.ProgramTest` |

Terratest predates `terraform test`. Its niche today is probing the deployed result from
outside (HTTP, AWS SDK, retries until healthy) and orchestrating several modules. Pulumi
needs no separate tool for that: the Automation API runs inside the same vitest suite.
LocalStack (`tflocal`, `pulumilocal`) makes integration tests cheap enough for CI.

## Talking points

- **Both have real unit tests with fake providers now.** `terraform test` (1.6) + mocks
  (1.7) caught up with what Pulumi users got from their language's test runners.
- **Terraform:** one built-in, declarative format. Mocks generate fake values from the
  provider schema. `command = plan` tests run without any apply. Good for module authors.
  Limits: HCL assertions, and tests can't share helpers beyond what HCL offers.
- **Pulumi:** your normal test toolchain (vitest/Jest/Mocha, coverage, watch mode, IDE
  integration, CI reporters). The mocks are lower level: you write `newResource` yourself
  and unwrap `Output<T>` by hand. Validation is just code, so it's testable like code.
- **Gotchas we hit while building this:**
  - Terraform: `run` blocks in one file **share state**. An `override_resource` inside a
    later run block was ignored, because the resource already existed from the first run.
    Hence the file-level override.
  - Pulumi: `setMocks` must be called before any resource is *constructed*. If the
    module under test creates resources at import time, import it *after* `setMocks`
    (dynamic `import()`).
- **Beyond unit tests:** see the table above. Mocks prove the logic, not the deployment.

## OpenTofu — good to know

`tofu test` runs the very same `tests/service.tftest.hcl` with identical results (4/4
verified with OpenTofu 1.13.2): `mock_provider`, `override_resource`, `expect_failures`
and `command = plan` all have parity.
