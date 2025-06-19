module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.5.0"
  context = var.context
  name    = var.name
}

module "oidc_authorizer_lambda" {
  source  = "bendoerr-terraform-modules/lambda/aws"
  version = "0.2.0"

  context = var.context
  name    = var.name

  description      = "OIDC Authorizer for API Gateway"
  filename         = var.lambda_zip_path != null ? var.lambda_zip_path : local_sensitive_file.bootstrap[0].filename
  source_code_hash = var.lambda_zip_path != null ? null : local_sensitive_file.bootstrap[0].content_base64sha256
  handler          = "bootstrap"
  runtime          = "provided.al2"
  architectures    = ["arm64"]

  publish     = true
  timeout     = 3
  memory_size = 128

  environment_variables = {
    JWKS_URI             = var.jwks_uri
    ACCEPTED_ISSUERS     = var.issuer_url
    ACCEPTED_AUDIENCES   = var.audience
    AWS_LAMBDA_LOG_LEVEL = upper(var.log_level)
  }
}

##############################
# API Gateway Authorizer
##############################
resource "aws_api_gateway_authorizer" "oidc" {
  name                             = module.label.id
  rest_api_id                      = var.rest_api_id
  authorizer_uri                   = module.oidc_authorizer_lambda.lambda_function_invoke_arn
  authorizer_credentials           = aws_iam_role.invocation_role.arn
  identity_source                  = var.token_location == "header" ? "method.request.header.${var.authorization_header}" : "method.request.querystring.${var.authorization_header}"
  type                             = "TOKEN"
  identity_validation_expression   = var.identity_validation_expression
  authorizer_result_ttl_in_seconds = var.cache_ttl
}

# Create IAM role for the authorizer Lambda invocation
resource "aws_iam_role" "invocation_role" {
  name = "${module.label.id}-invoke"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })

  tags = module.label.tags
}

# Create IAM policy for API Gateway to invoke Lambda
resource "aws_iam_policy" "lambda_invocation" {
  name        = "${module.label.id}-invoke"
  description = "Allow API Gateway to invoke OIDC authorizer Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "lambda:InvokeFunction"
      Effect   = "Allow"
      Resource = module.oidc_authorizer_lambda.lambda_function_arn
    }]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_invocation" {
  role       = aws_iam_role.invocation_role.name
  policy_arn = aws_iam_policy.lambda_invocation.arn
}

# Allow API Gateway to invoke Lambda authorizer
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.oidc_authorizer_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any resource, method, and stage
  source_arn = "${var.rest_api_execution_arn}/*/*/*"
}

##############################
# Lambda code download
##############################
# Download Lambda code from GitHub if no custom ZIP is provided
data "github_release" "bootstrap" {
  count       = var.lambda_zip_path == null ? 1 : 0
  repository  = "oidc-authorizer"
  owner       = "lmammino"
  retrieve_by = "tag"
  release_tag = var.oidc_authorizer_version
}

data "http" "bootstrap" {
  count = var.lambda_zip_path == null ? 1 : 0
  url   = data.github_release.bootstrap[0].assets[0].browser_download_url

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 204], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

resource "local_sensitive_file" "bootstrap" {
  count          = var.lambda_zip_path == null ? 1 : 0
  filename       = "${path.module}/lambda/${data.github_release.bootstrap[0].assets[0].name}"
  content_base64 = data.http.bootstrap[0].response_body_base64
}
