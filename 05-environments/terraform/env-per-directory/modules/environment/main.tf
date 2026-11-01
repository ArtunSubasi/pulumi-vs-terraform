# Shared environment code. No backend, no tfvars, no terraform.workspace:
# everything environment-specific comes in through variables from dev/ and prod/.

variable "environment" {
  type = string
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
  prefix = var.environment
}

resource "local_file" "settings" {
  # path.root is the calling env directory (dev/ or prod/), not this module.
  filename = "${path.root}/out/${var.environment}.json"
  content = jsonencode({
    environment = var.environment
    log_level   = var.log_level
    instances   = random_pet.instance[*].id
  })
}

output "instances" {
  value = random_pet.instance[*].id
}
