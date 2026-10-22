# OpenTofu only (*.tofu is ignored by Terraform). Client-side state + plan encryption, since 1.7.
# Set the passphrase outside the code, for EVERY command (init included):
#   export TF_VAR_state_passphrase='at least 16 characters'

variable "state_passphrase" {
  type      = string
  sensitive = true
}

terraform {
  required_version = ">= 1.8" # variables in the encryption block

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }

  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.passphrase
    }
    state {
      method   = method.aes_gcm.default
      enforced = true # refuse to ever write unencrypted state
    }
    plan {
      method   = method.aes_gcm.default
      enforced = true
    }
  }
}

resource "random_password" "db" {
  length  = 20
  special = false
}

output "password" {
  value     = random_password.db.result
  sensitive = true
}
