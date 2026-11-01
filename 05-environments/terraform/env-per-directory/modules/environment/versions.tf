# Modules declare sources only; the root modules (dev/, prod/) pin versions.
terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}
