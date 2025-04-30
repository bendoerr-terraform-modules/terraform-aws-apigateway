module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.5.0"
  context = var.context
  name    = var.name
}

resource "aws_api_gateway_domain_name" "this" {
  count = var.enabled ? 1 : 0

  domain_name = var.domain_name

  # Use the appropriate certificate ARN based on the certificate type
  regional_certificate_arn = var.certificate_type == "REGIONAL" ? var.certificate_arn : null
  certificate_arn          = var.certificate_type == "EDGE" ? var.certificate_arn : null

  security_policy = var.security_policy
  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = module.label.tags
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.enabled && var.create_base_path_mapping ? 1 : 0

  api_id      = var.api_id
  stage_name  = var.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  base_path   = var.base_path
}
