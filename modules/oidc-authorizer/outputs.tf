output "authorizer_id" {
  description = "ID of the API Gateway authorizer"
  value       = aws_api_gateway_authorizer.oidc.id
}

output "authorizer_name" {
  description = "Name of the API Gateway authorizer"
  value       = aws_api_gateway_authorizer.oidc.name
}

output "lambda_function_arn" {
  description = "ARN of the OIDC authorizer Lambda function"
  value       = module.oidc_authorizer_lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the OIDC authorizer Lambda function"
  value       = module.oidc_authorizer_lambda.lambda_function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the OIDC authorizer Lambda function"
  value       = module.oidc_authorizer_lambda.lambda_function_invoke_arn
}

output "invocation_role_arn" {
  description = "ARN of the IAM role used for API Gateway to invoke the authorizer"
  value       = aws_iam_role.invocation_role.arn
}
