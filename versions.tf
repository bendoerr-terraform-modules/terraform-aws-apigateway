terraform {
  # Require 1.3.0+ for robust optional() attribute support (used extensively in this module)
  required_version = ">= 1.3.0"

  required_providers {
    # Use a v5.x.x version of the AWS provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
