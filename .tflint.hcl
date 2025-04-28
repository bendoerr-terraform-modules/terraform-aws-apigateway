plugin "terraform" {
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  version = "0.12.0"
  enabled = true
  preset  = "all"
}

plugin "aws" {
  source     = "github.com/terraform-linters/tflint-ruleset-aws"
  version    = "0.38.0"
  enabled    = true
  deep_check = false
}
