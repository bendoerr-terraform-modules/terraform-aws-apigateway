provider "aws" {
  region = "us-east-1"
}

module "account_logs" {
  source  = "../../modules/account-logs"
  context = module.context
}
