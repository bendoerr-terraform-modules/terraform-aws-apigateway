# Ben's Terraform AWS API Gateway Custom Domain Module

## About The Module

This Terraform module provides a way to configure custom domain names for AWS API Gateway REST APIs. It handles:

- Creating an API Gateway domain name resource with your custom domain
- Setting up TLS certificate configuration for secure connections (supporting both REGIONAL and EDGE certificates)
- Creating base path mappings to connect your API stages to the custom domain
- Providing DNS configuration details as outputs for easy Route 53 integration
- Supporting both regional and edge-optimized endpoint types for different access patterns

The module is designed as a submodule for the main API Gateway module but can also be used independently when you need to manage API Gateway account settings separately from your API resources.

## Usage

<!-- BEGIN_TF_DOCS -->

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 6.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.96.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_label"></a> [label](#module_label) | bendoerr-terraform-modules/label/null | 0.5.0 |

### Resources

| Name | Type |
|------|------|
| [aws_api_gateway_base_path_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_id"></a> [api_id](#input_api_id) | ID of the API Gateway REST API | `string` | n/a | yes |
| <a name="input_base_path"></a> [base_path](#input_base_path) | Base path to map the API under the domain (empty string for root) | `string` | `""` | no |
| <a name="input_certificate_arn"></a> [certificate_arn](#input_certificate_arn) | ARN of the ACM certificate to use for the custom domain | `string` | `null` | no |
| <a name="input_certificate_type"></a> [certificate_type](#input_certificate_type) | Type of certificate for the custom domain. Valid values: EDGE, REGIONAL | `string` | `"REGIONAL"` | no |
| <a name="input_context"></a> [context](#input_context) | Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module. | <pre>object({<br> attributes = list(string)<br> dns_namespace = string<br> environment = string<br> instance = string<br> instance_short = string<br> namespace = string<br> region = string<br> region_short = string<br> role = string<br> role_short = string<br> project = string<br> tags = map(string)<br> })</pre> | n/a | yes |
| <a name="input_create_base_path_mapping"></a> [create_base_path_mapping](#input_create_base_path_mapping) | Whether to create a base path mapping for the custom domain | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain_name](#input_domain_name) | Custom domain name for the API Gateway | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input_enabled) | Whether to enable a custom domain name for the API Gateway | `bool` | `false` | no |
| <a name="input_endpoint_type"></a> [endpoint_type](#input_endpoint_type) | Endpoint type for the domain name. Valid values: EDGE, REGIONAL | `string` | `"REGIONAL"` | no |
| <a name="input_name"></a> [name](#input_name) | A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module. | `string` | `"thing"` | no |
| <a name="input_security_policy"></a> [security_policy](#input_security_policy) | TLS security policy for the custom domain. Valid values: TLS_1_0, TLS_1_2 | `string` | `"TLS_1_2"` | no |
| <a name="input_stage_name"></a> [stage_name](#input_stage_name) | Name of the API Gateway stage | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_arn"></a> [certificate_arn](#output_certificate_arn) | ARN of the certificate used for the custom domain |
| <a name="output_cloudfront_domain_name"></a> [cloudfront_domain_name](#output_cloudfront_domain_name) | CloudFront distribution domain name associated with the custom domain (EDGE endpoint type) |
| <a name="output_cloudfront_zone_id"></a> [cloudfront_zone_id](#output_cloudfront_zone_id) | CloudFront distribution hosted zone ID associated with the custom domain (EDGE endpoint type) |
| <a name="output_domain_name"></a> [domain_name](#output_domain_name) | Custom domain name for the API Gateway |
| <a name="output_domain_name_id"></a> [domain_name_id](#output_domain_name_id) | ID of the custom domain name |
| <a name="output_regional_domain_name"></a> [regional_domain_name](#output_regional_domain_name) | Regional domain name associated with the custom domain (REGIONAL endpoint type) |
| <a name="output_regional_zone_id"></a> [regional_zone_id](#output_regional_zone_id) | Regional hosted zone ID associated with the custom domain (REGIONAL endpoint type) |

<!-- END_TF_DOCS -->
