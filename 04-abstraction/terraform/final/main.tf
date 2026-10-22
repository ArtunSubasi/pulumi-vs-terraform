variable "services" {
  description = "Services to generate local dev config for. Public ones also get a TLS key."
  type = map(object({
    port   = number
    public = optional(bool, false)
  }))
  default = {
    api    = { port = 8080, public = true }
    worker = { port = 9090 }
    admin  = { port = 8081, public = true }
  }
}

# Loop: one module instance per service
module "service" {
  source   = "./modules/service"
  for_each = var.services

  name   = each.key
  port   = each.value.port
  public = each.value.public
}

# Nested blocks generated from data: one `source` block per service config
data "archive_file" "bundle" {
  type        = "zip"
  output_path = "${path.module}/out/bundle.zip"

  dynamic "source" {
    for_each = module.service
    content {
      filename = "${source.key}.json"
      content  = source.value.config
    }
  }
}

output "config_files" {
  value = { for name, svc in module.service : name => svc.config_file }
}

output "public_keys" {
  value = { for name, svc in module.service : name => svc.public_key if svc.public_key != null }
}

output "bundle" {
  value = data.archive_file.bundle.output_path
}
