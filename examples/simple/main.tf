terraform {
  # Anything greater than the 1.0.0 release should be sufficient
  required_version = ">= 1.0.0"

  required_providers {
    # Use a v5.x.x version of the AWS provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "this" {
  source  = "../.."
  context = module.context.shared
  name    = "example"
}
