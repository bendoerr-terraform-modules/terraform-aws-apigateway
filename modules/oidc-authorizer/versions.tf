terraform {
  required_version = ">= 1.0.0" # floor-reason: submodule floor predates root's 1.3.0 bump; raising is consumer-breaking, deferred (2026-08-13)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}
