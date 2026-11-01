# OpenTofu only (*.tofu is ignored by Terraform). Same state + plan encryption as
# 06-secrets/opentofu, but the key comes from AWS KMS instead of a passphrase.
# Credentials come from the AWS environment (AWS_PROFILE, `aws login`). The region is
# pinned below: the key provider ignores the region in your AWS profile.
# The key itself is created outside this project: ../../key.sh create

terraform {
  required_version = ">= 1.8"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }

  encryption {
    key_provider "aws_kms" "demo" {
      kms_key_id = "alias/tf-vs-pulumi-demo"
      region     = "eu-central-1"
      key_spec   = "AES_256" # KMS returns a fresh data key, tofu stores it encrypted in the state
    }
    method "aes_gcm" "default" {
      keys = key_provider.aws_kms.demo
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
