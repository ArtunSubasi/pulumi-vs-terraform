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
- **Beyond unit tests:** Terraform has `check` blocks (continuous assertions) and
  `terraform test` with real providers (integration). Pulumi has integration tests with
  the Automation API, and policy as code (CrossGuard). Terraform 1.17 made
  Terraform Policy GA (`-policies`).

## OpenTofu — good to know

`tofu test` runs the very same `tests/service.tftest.hcl` with identical results (4/4
verified with OpenTofu 1.13.2): `mock_provider`, `override_resource`, `expect_failures`
and `command = plan` all have parity.
