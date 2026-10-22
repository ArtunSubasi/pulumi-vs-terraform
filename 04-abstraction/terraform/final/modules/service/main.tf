variable "name" {
  type = string
}

variable "port" {
  type = number
}

variable "public" {
  type    = bool
  default = false
}

resource "random_password" "db" {
  length  = 20
  special = false
}

resource "local_file" "config" {
  filename = "${path.root}/out/${var.name}.json"
  content = jsonencode({
    service     = var.name
    port        = var.port
    db_password = random_password.db.result
  })
}

# Conditional resource: only public services get a TLS key
resource "tls_private_key" "this" {
  count     = var.public ? 1 : 0
  algorithm = "ED25519"
}

output "config" {
  value     = local_file.config.content
  sensitive = true
}

output "config_file" {
  value = local_file.config.filename
}

output "public_key" {
  value = var.public ? trimspace(tls_private_key.this[0].public_key_openssh) : null
}
