variable "prefix" {
  description = "Prefix for the generated name. Change it to see a replacement in the plan."
  type        = string
  default     = "demo"
}

resource "random_pet" "name" {
  prefix = var.prefix
  length = 2
}

# LIVE: resource "random_password" "db" — length 20, no special characters

output "pet_name" {
  value = random_pet.name.id
}

# LIVE: output "password" — first without `sensitive`, show the error, then add it
