output "id" {
  value       = module.label.id
  description = "The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "tags" {
  value       = module.label.tags
  description = "The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "name" {
  value       = var.name
  description = "The provided name given to the module."
}

output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_name" {
  description = "Name of the REST API"
  value       = aws_api_gateway_rest_api.this.name
}

output "rest_api_execution_arn" {
  description = "Execution ARN part to be used in lambda_permission's source_arn"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "rest_api_arn" {
  description = "ARN of the REST API"
  value       = aws_api_gateway_rest_api.this.arn
}

output "rest_api_root_resource_id" {
  description = "Resource ID of the REST API's root"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}

output "deployment_id" {
  description = "ID of the API Gateway deployment"
  value       = aws_api_gateway_deployment.this.id
}

output "stage_id" {
  description = "ID of the API Gateway stage"
  value       = aws_api_gateway_stage.this.id
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_invoke_url" {
  description = "URL to invoke the API pointing to the stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_execution_arn" {
  description = "Execution ARN to be used in permissions policy"
  value       = aws_api_gateway_stage.this.execution_arn
}

output "stage_arn" {
  description = "ARN of the API Gateway stage"
  value       = aws_api_gateway_stage.this.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for API Gateway access logs"
  value       = local.access_log_enabled ? aws_cloudwatch_log_group.api_gateway_access_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for API Gateway access logs"
  value       = local.access_log_enabled ? aws_cloudwatch_log_group.api_gateway_access_logs[0].arn : null
}

output "execution_log_group_name" {
  description = "Name of the CloudWatch log group for API Gateway execution logs"
  value       = aws_cloudwatch_log_group.api_gateway_execution_logs.name
}

output "execution_log_group_arn" {
  description = "ARN of the CloudWatch log group for API Gateway execution logs"
  value       = aws_cloudwatch_log_group.api_gateway_execution_logs.arn
}

output "method_settings_id" {
  description = "IDs of the API Gateway method settings"
  value = length(aws_api_gateway_method_settings.this) > 0 ? {
    for path, settings in aws_api_gateway_method_settings.this : path => settings.id
  } : null
}
