variable "name" {
  type    = string
  default = "api"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "name must be lowercase letters, digits and dashes."
  }
}

variable "port" {
  type    = number
  default = 8080

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "port must be between 1024 and 65535 (no privileged ports)."
  }
}

resource "random_password" "db" {
  length  = 20
  special = false
}

resource "local_file" "config" {
  filename = "${path.module}/out/${var.name}.json"
  content = jsonencode({
    service     = var.name
    port        = var.port
    db_password = random_password.db.result
  })
}

output "config_file" {
  value = local_file.config.filename
}

output "connection_string" {
  value     = "postgres://${var.name}:${random_password.db.result}@db.internal:5432/${var.name}"
  sensitive = true
}
