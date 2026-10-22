# terraform test — runs from the module root. With mock providers nothing is written to disk.
mock_provider "random" {}
mock_provider "local" {}

# Deterministic "generated" password for every run in this file.
# (File level on purpose: runs share state, so a per-run override would only
# apply if that run is the one creating the resource.)
override_resource {
  target = random_password.db
  values = { result = "fixed-for-test" }
}

run "config_has_name_and_port" {
  command = apply # against the mocks: no real resources

  variables {
    name = "billing"
    port = 9000
  }

  assert {
    condition     = jsondecode(local_file.config.content).port == 9000
    error_message = "config must contain the port"
  }

  assert {
    condition     = local_file.config.filename == "./out/billing.json"
    error_message = "config file must be named after the service"
  }
}

run "connection_string_uses_password" {
  command = apply

  assert {
    condition     = nonsensitive(output.connection_string) == "postgres://api:fixed-for-test@db.internal:5432/api"
    error_message = "unexpected connection string: ${nonsensitive(output.connection_string)}"
  }
}

run "rejects_privileged_port" {
  command = plan

  variables {
    port = 80
  }

  expect_failures = [var.port]
}

run "rejects_uppercase_name" {
  command = plan

  variables {
    name = "Billing"
  }

  expect_failures = [var.name]
}
