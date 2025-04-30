output "cloudwatch_role_arn" {
  description = "ARN of the IAM role used by API Gateway to write to CloudWatch Logs"
  value       = var.enabled ? aws_iam_role.api_gateway_cloudwatch_logs[0].arn : null
}

output "cloudwatch_role_name" {
  description = "Name of the IAM role used by API Gateway to write to CloudWatch Logs"
  value       = var.enabled ? aws_iam_role.api_gateway_cloudwatch_logs[0].name : null
}
