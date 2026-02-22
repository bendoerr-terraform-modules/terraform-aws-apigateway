provider "aws" {
  region = "us-east-1"
}

# Use the API Gateway module
module "this" {
  source = "../.."

  context     = module.context
  name        = "simple"
  description = "Hello World API Example"

  openapi_config = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "Hello World API"
      version = "1.0"
    }
    paths = {
      "/hello" = {
        get = {
          x-amazon-apigateway-integration = {
            uri                 = "arn:aws:apigateway:${module.context.region}:lambda:path/2015-03-31/functions/${module.lambda.lambda_function_arn}/invocations"
            type                = "aws_proxy"
            httpMethod          = "POST"
            passthroughBehavior = "when_no_match"
            timeoutInMillis     = 29000
            contentHandling     = "CONVERT_TO_TEXT"
          }
          responses = {
            "200" = {
              description = "Success response"
              content = {
                "application/json" = {
                  schema = {
                    type = "object"
                  }
                }
              }
            }
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

module "lambda" {
  source  = "bendoerr-terraform-modules/lambda/aws"
  context = module.context
  version = "0.2.0"

  name        = "simple"
  description = "Example Lambda Handler"
  filename    = data.archive_file.lambda_zip.output_path
  handler     = "index.handler"
  runtime     = "nodejs18.x"
}

# Grant permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any API Gateway method on the /hello path
  source_arn = "${module.this.rest_api_execution_arn}/*/*/*"
}

# Create Lambda deployment package with archive_file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/index.js"
  output_path = "${path.module}/../lambda/index.zip"
}
