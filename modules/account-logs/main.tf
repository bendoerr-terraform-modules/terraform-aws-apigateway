module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.5.0"
  context = var.context
  name    = var.name
}

data "aws_caller_identity" "current" {}

# IAM role for API Gateway to write to CloudWatch Logs
resource "aws_iam_role" "api_gateway_cloudwatch_logs" {
  count = var.enabled ? 1 : 0

  description = "Allow API Gateway to CloudWatch integration"
  name        = module.label.id
  tags        = module.label.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

}

# Policy to allow API Gateway to write to CloudWatch Logs
resource "aws_iam_policy" "api_gateway_cloudwatch_logs" {
  count = var.enabled ? 1 : 0

  description = "Allow API Gateway to CloudWatch integration"
  name        = module.label.id
  tags        = module.label.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups"
        ]
        Resource = [
          # API Gateway execution logs
          "arn:aws:logs:${var.context.region}:${data.aws_caller_identity.current.account_id}:log-group:API-Gateway-Execution-Logs*",
          # API Gateway access logs
          "arn:aws:logs:${var.context.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = [
          # API Gateway execution logs
          "arn:aws:logs:${var.context.region}:${data.aws_caller_identity.current.account_id}:log-group:API-Gateway-Execution-Logs*:*",
          # API Gateway access logs
          "arn:aws:logs:${var.context.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
  count = var.enabled ? 1 : 0

  policy_arn = aws_iam_policy.api_gateway_cloudwatch_logs[0].arn
  role       = aws_iam_role.api_gateway_cloudwatch_logs[0].id
}

# Account-level settings for API Gateway
resource "aws_api_gateway_account" "this" {
  count = var.enabled ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_logs[0].arn
}
