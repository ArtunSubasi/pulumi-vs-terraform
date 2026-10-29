terraform {
  required_version = ">= 1.11"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Region comes from AWS_REGION / the AWS profile, like the credentials.
provider "aws" {}
