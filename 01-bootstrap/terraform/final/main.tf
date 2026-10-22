resource "random_pet" "server" {
  length = 2
}

output "server_name" {
  value = random_pet.server.id
}
