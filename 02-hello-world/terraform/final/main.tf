variable "prefix" {
  description = "Prefix for the generated name. Change it to see a replacement in the plan."
  type        = string
  default     = "demo"
}

resource "random_pet" "name" {
  prefix = var.prefix
  length = 2
}

resource "random_password" "db" {
  length  = 20
  special = false
}

output "pet_name" {
  value = random_pet.name.id
}

output "password" {
  value     = random_password.db.result
  sensitive = true
}
