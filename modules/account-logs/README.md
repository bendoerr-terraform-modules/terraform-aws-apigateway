# Ben's Terraform AWS API Gateway Account Settings Module

## About The Module

This Terraform module configures AWS API Gateway account-level settings that enable CloudWatch logging for all API Gateways in a region. It handles:

- Creating an IAM role with permissions for API Gateway to write to CloudWatch Logs
- Configuring the API Gateway account settings to use this role
- Providing an optional cleanup mechanism via the `reset_on_delete` parameter

The module is designed as a submodule for the main API Gateway module but can also be used independently when you need to manage API Gateway account settings separately from your API resources.

## Usage

```hcl
module "api_gateway_account" {
  source  = "bendoerr-terraform-modules/apigateway/aws/modules/account"

  context = module.context
  name    = "api-logs"
}
```

<!-- BEGIN_TF_DOCS -->

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 5.0 |

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
| [aws_api_gateway_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_iam_policy.api_gateway_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.api_gateway_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.api_gateway_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input_context) | Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module. | <pre>object({<br> attributes = list(string)<br> dns_namespace = string<br> environment = string<br> instance = string<br> instance_short = string<br> namespace = string<br> region = string<br> region_short = string<br> role = string<br> role_short = string<br> project = string<br> tags = map(string)<br> })</pre> | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input_enabled) | Whether to enable API Gateway account settings | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input_name) | A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module. | `string` | `"apigtwy-logs"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_role_arn"></a> [cloudwatch_role_arn](#output_cloudwatch_role_arn) | ARN of the IAM role used by API Gateway to write to CloudWatch Logs |
| <a name="output_cloudwatch_role_name"></a> [cloudwatch_role_name](#output_cloudwatch_role_name) | Name of the IAM role used by API Gateway to write to CloudWatch Logs |

<!-- END_TF_DOCS -->
