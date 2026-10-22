terraform {
  required_version = ">= 1.11"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9" # ephemeral "random_password" needs >= 3.7
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}
