module "environment" {
  source = "../modules/environment"

  environment    = "dev"
  instance_count = 1
  log_level      = "debug"
}

output "instances" {
  value = module.environment.instances
}
