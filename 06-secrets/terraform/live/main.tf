# Set it outside the code:  export TF_VAR_api_token=...
variable "api_token" {
  type      = string
  sensitive = true
}

resource "random_password" "db" {
  length  = 20
  special = false
}

# local_sensitive_file: the content is hidden in plan output (the file itself is plain text)
resource "local_sensitive_file" "env" {
  filename = "${path.module}/out/.env"
  content  = "API_TOKEN=${var.api_token}\nDB_PASSWORD=${random_password.db.result}\n"
}

# LIVE: output "connection_string" — "postgres://app:<db password>@db.internal:5432/app", sensitive

# Ephemeral (Terraform 1.10+): generated on every run, never written to state or plan.
# It can only flow into write-only attributes (e.g. aws_ssm_parameter.value_wo, Terraform 1.11+),
# ephemeral outputs/variables or provider config. No offline provider has a write-only attribute.
ephemeral "random_password" "bootstrap" {
  length = 24
}
