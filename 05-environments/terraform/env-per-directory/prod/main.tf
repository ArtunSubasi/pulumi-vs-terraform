module "environment" {
  source = "../modules/environment"

  environment    = "prod"
  instance_count = 3
}

output "instances" {
  value = module.environment.instances
}
