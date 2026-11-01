# prod: its own backend, outside the dev directory. Stands in for a remote backend
# so the demo stays offline. In a real setup this is the prod account's bucket:
#
#   backend "s3" {
#     bucket       = "acme-prod-tfstate"
#     key          = "environments/terraform.tfstate"
#     region       = "eu-north-1"
#     use_lockfile = true
#   }
terraform {
  backend "local" {
    path = "../.state/prod/terraform.tfstate"
  }
}
