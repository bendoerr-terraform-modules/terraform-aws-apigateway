module "context" {
  source    = "bendoerr-terraform-modules/context/null"
  version   = "0.5.0"
  namespace = var.namespace
  role      = "apigateway"
  region    = "us-east-1"
  project   = "example"
  long_dns  = true
}
