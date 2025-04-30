output "domain_name" {
  description = "Custom domain name for the API Gateway"
  value       = var.enabled ? aws_api_gateway_domain_name.this[0].domain_name : null
}

output "domain_name_id" {
  description = "ID of the custom domain name"
  value       = var.enabled ? aws_api_gateway_domain_name.this[0].id : null
}

output "certificate_arn" {
  description = "ARN of the certificate used for the custom domain"
  value       = var.enabled ? var.certificate_arn : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name associated with the custom domain (EDGE endpoint type)"
  value       = var.enabled && var.endpoint_type == "EDGE" ? aws_api_gateway_domain_name.this[0].cloudfront_domain_name : null
}

output "cloudfront_zone_id" {
  description = "CloudFront distribution hosted zone ID associated with the custom domain (EDGE endpoint type)"
  value       = var.enabled && var.endpoint_type == "EDGE" ? aws_api_gateway_domain_name.this[0].cloudfront_zone_id : null
}

output "regional_domain_name" {
  description = "Regional domain name associated with the custom domain (REGIONAL endpoint type)"
  value       = var.enabled && var.endpoint_type == "REGIONAL" ? aws_api_gateway_domain_name.this[0].regional_domain_name : null
}

output "regional_zone_id" {
  description = "Regional hosted zone ID associated with the custom domain (REGIONAL endpoint type)"
  value       = var.enabled && var.endpoint_type == "REGIONAL" ? aws_api_gateway_domain_name.this[0].regional_zone_id : null
}
