resource "random_password" "db" {
  length  = 16
  special = false
}

# A file on disk is the cheapest "real" resource: easy to change behind the tool's back.
resource "local_file" "config" {
  filename = "${path.module}/out/app.conf"
  content  = "db_user=app\nport=5432\n"
}

output "config_file" {
  value = local_file.config.filename
}
