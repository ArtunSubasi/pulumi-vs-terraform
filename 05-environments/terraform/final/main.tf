variable "environment" {
  description = "Must match the selected workspace (guards against the wrong -var-file)."
  type        = string
}

variable "instance_count" {
  type = number
}

variable "log_level" {
  type    = string
  default = "info"
}

resource "random_pet" "instance" {
  count  = var.instance_count
  prefix = terraform.workspace
}

resource "local_file" "settings" {
  filename = "${path.module}/out/${terraform.workspace}.json"
  content = jsonencode({
    environment = var.environment
    log_level   = var.log_level
    instances   = random_pet.instance[*].id
  })

  lifecycle {
    precondition {
      condition     = var.environment == terraform.workspace
      error_message = "envs/${var.environment}.tfvars used in workspace \"${terraform.workspace}\"."
    }
  }
}

output "instances" {
  value = random_pet.instance[*].id
}
