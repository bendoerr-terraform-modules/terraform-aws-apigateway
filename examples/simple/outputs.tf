output "id" {
  value       = module.this.id
  description = "The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "tags" {
  value       = module.this.tags
  description = "The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "name" {
  value       = module.this.name
  description = "The provided name given to the module."
}

output "rest_api_id" {
  description = "ID of the REST API"
  value       = module.this.rest_api_id
}

output "rest_api_name" {
  description = "Name of the REST API"
  value       = module.this.rest_api_name
}

output "stage_invoke_url" {
  description = "URL to invoke the API"
  value       = module.this.stage_invoke_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "hello_endpoint" {
  description = "Complete URL to access the hello endpoint"
  value       = "${module.this.stage_invoke_url}/hello"
}

output "api_invoke_url" {
  description = "URL to invoke the API"
  value       = "${module.this.stage_invoke_url}/hello"
}
