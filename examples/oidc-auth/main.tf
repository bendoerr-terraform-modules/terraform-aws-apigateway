provider "aws" {
  region = "us-east-1"
}

# Create API Gateway
module "api_gateway" {
  source = "../.."

  context     = module.context
  name        = "oidc-protected"
  description = "API Gateway with OIDC Authorization"

  openapi_config = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "OIDC Protected API"
      version = "1.0"
    }
    paths = {
      "/public" = {
        get = {
          x-amazon-apigateway-integration = {
            uri        = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.lambda_public.lambda_function_arn}/invocations"
            type       = "aws_proxy"
            httpMethod = "POST"
          }
          responses = {
            "200" = {
              description = "Success"
            }
          }
        }
      }
      "/protected" = {
        get = {
          security = [{
            oidc_auth = []
          }]
          x-amazon-apigateway-integration = {
            uri        = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.lambda_protected.lambda_function_arn}/invocations"
            type       = "aws_proxy"
            httpMethod = "POST"
          }
          responses = {
            "200" = {
              description = "Success"
            }
          }
        }
      }
    },
    components = {
      securitySchemes = {
        oidc_auth = {
          type = "apiKey"
          name = "Authorization"
          in   = "header"
          "x-amazon-apigateway-authtype" : "custom"
          "x-amazon-apigateway-authorizer" = {
            type                         = "token"
            authorizerUri                = module.oidc_authorizer.lambda_function_invoke_arn
            authorizerCredentials        = module.oidc_authorizer.invocation_role_arn
            identityValidationExpression = "^Bearer .+$"
            authorizerResultTtlInSeconds = 300
          }
        }
      }
    }
  })

  # Stage configuration (grouped)
  stage_config = {
    name        = "v1"
    description = "Version 1"
  }

  # Logging configuration (grouped)
  logging_config = {
    access_logs = {
      enabled = true
    }
  }
}

# Account settings for CloudWatch logs
module "account_logs" {
  source = "../../modules/account-logs"

  context = module.context
}

# Create OIDC authorizer
module "oidc_authorizer" {
  source = "../../modules/oidc-authorizer"

  context = module.context
  name    = "auth0-oidc"

  # API Gateway details
  rest_api_id            = module.api_gateway.rest_api_id
  rest_api_execution_arn = module.api_gateway.rest_api_execution_arn

  # OIDC configuration - replace with your actual values
  jwks_uri   = "https://auth.example.com/.well-known/jwks.json"
  issuer_url = "https://auth.example.com/"
  audience   = "https://api.example.com"

  # Optional customization
  token_location       = "header"
  authorization_header = "Authorization"
  cache_ttl            = 300
  log_level            = "debug"
}

module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.5.0"
  context = module.context
  name    = "api"
}

# Public Lambda function (no authorization)
module "lambda_public" {
  source  = "bendoerr-terraform-modules/lambda/aws"
  version = "0.2.0"

  context     = module.context
  name        = "${module.label.id}-public"
  description = "${module.label.id}-public"


  filename = data.archive_file.lambda_public.output_path
  handler  = "index.handler"
  runtime  = "nodejs18.x"
}

# Protected Lambda function (requires authorization)
module "lambda_protected" {
  source  = "bendoerr-terraform-modules/lambda/aws"
  version = "0.2.0"

  context     = module.context
  name        = "${module.label.id}-protected"
  description = "${module.label.id}-protected"

  filename = data.archive_file.lambda_protected.output_path
  handler  = "index.handler"
  runtime  = "nodejs18.x"
}

# Create Lambda deployment packages
data "archive_file" "lambda_public" {
  type        = "zip"
  output_path = "${path.module}/lambda_public.zip"

  source {
    content  = <<EOF
exports.handler = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "This is a public endpoint - no auth required!" }),
    headers: { "Content-Type": "application/json" }
  };
};
EOF
    filename = "index.js"
  }
}

data "archive_file" "lambda_protected" {
  type        = "zip"
  output_path = "${path.module}/lambda_protected.zip"

  source {
    content  = <<EOF
exports.handler = async (event) => {
  // Get user info from requestContext.authorizer added by the Lambda authorizer
  const user = event.requestContext.authorizer || {};

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "This is a protected endpoint - auth required!",
      user: user.principalId || "Unknown user",
      scopes: user.scope || []
    }),
    headers: { "Content-Type": "application/json" }
  };
};
EOF
    filename = "index.js"
  }
}

# Lambda permissions
resource "aws_lambda_permission" "public_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_public.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*/public"
}

resource "aws_lambda_permission" "protected_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_protected.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*/protected"
}

data "aws_region" "current" {}
