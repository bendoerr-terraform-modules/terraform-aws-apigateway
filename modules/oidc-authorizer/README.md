# Ben's Terraform AWS API Gateway OIDC Authorizer Module

## About The Module

This Terraform module configures OpenID Connect (OIDC) authorizers for AWS API Gateway REST APIs. It handles:

- Creating and configuring API Gateway authorizers using JWT tokens
- Setting up identity sources from request headers, query strings, or stage variables
- Managing authorizer caching and TTL settings
- Supporting multiple OIDC provider integrations (Auth0, Cognito, Okta, etc.)
- Simplifying OIDC configuration for secure API access control

The module is designed as a submodule for the main API Gateway module but can also be used independently when you need to manage API Gateway account settings separately from your API resources.

## Usage

```hcl
# Create OIDC authorizer
module "oidc_authorizer" {
  source = "../../modules/oidc-authorizer"

  context = module.context
  name    = "authz"

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
}
```

<!-- BEGIN_TF_DOCS -->

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 5.0 |
| <a name="requirement_github"></a> [github](#requirement_github) | ~> 6.0 |
| <a name="requirement_http"></a> [http](#requirement_http) | ~> 3.0 |
| <a name="requirement_local"></a> [local](#requirement_local) | 2.5.2 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.96.0 |
| <a name="provider_github"></a> [github](#provider_github) | 6.6.0 |
| <a name="provider_http"></a> [http](#provider_http) | 3.5.0 |
| <a name="provider_local"></a> [local](#provider_local) | 2.5.2 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_label"></a> [label](#module_label) | bendoerr-terraform-modules/label/null | 0.5.0 |
| <a name="module_oidc_authorizer_lambda"></a> [oidc_authorizer_lambda](#module_oidc_authorizer_lambda) | bendoerr-terraform-modules/lambda/aws | 0.1.2 |

### Resources

| Name | Type |
|------|------|
| [aws_api_gateway_authorizer.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer) | resource |
| [aws_iam_policy.lambda_invocation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.invocation_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_invocation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_permission.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [local_sensitive_file.bootstrap](https://registry.terraform.io/providers/hashicorp/local/2.5.2/docs/resources/sensitive_file) | resource |
| [github_release.bootstrap](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [http_http.bootstrap](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audience"></a> [audience](#input_audience) | Expected audience for the tokens (client ID of your application) | `string` | n/a | yes |
| <a name="input_authorization_header"></a> [authorization_header](#input_authorization_header) | Name of the header or query parameter containing the token | `string` | `"Authorization"` | no |
| <a name="input_cache_ttl"></a> [cache_ttl](#input_cache_ttl) | Time to live in seconds for the authorizer cache | `number` | `300` | no |
| <a name="input_context"></a> [context](#input_context) | Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module. | <pre>object({<br> attributes = list(string)<br> dns_namespace = string<br> environment = string<br> instance = string<br> instance_short = string<br> namespace = string<br> region = string<br> region_short = string<br> role = string<br> role_short = string<br> project = string<br> tags = map(string)<br> })</pre> | n/a | yes |
| <a name="input_identity_validation_expression"></a> [identity_validation_expression](#input_identity_validation_expression) | Regular expression to validate the token format (optional) | `string` | `null` | no |
| <a name="input_issuer_url"></a> [issuer_url](#input_issuer_url) | URL of the OIDC issuer (e.g., <https://accounts.google.com>) | `string` | n/a | yes |
| <a name="input_jwks_uri"></a> [jwks_uri](#input_jwks_uri) | The URL of the OIDC provider JWKS (Endpoint providing public keys for verification). | `string` | n/a | yes |
| <a name="input_lambda_zip_path"></a> [lambda_zip_path](#input_lambda_zip_path) | Path to a custom Lambda ZIP file (if not provided, will download from GitHub) | `string` | `null` | no |
| <a name="input_log_level"></a> [log_level](#input_log_level) | Log level for the Lambda function (debug, info, warn, error) | `string` | `"error"` | no |
| <a name="input_name"></a> [name](#input_name) | A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module. | `string` | `"oidc-authorizer"` | no |
| <a name="input_oidc_authorizer_version"></a> [oidc_authorizer_version](#input_oidc_authorizer_version) | Version of oidc-authorizer to use (only used when downloading from GitHub) | `string` | `"0.1.2"` | no |
| <a name="input_rest_api_execution_arn"></a> [rest_api_execution_arn](#input_rest_api_execution_arn) | Execution ARN of the API Gateway REST API | `string` | n/a | yes |
| <a name="input_rest_api_id"></a> [rest_api_id](#input_rest_api_id) | ID of the API Gateway REST API to attach the authorizer to | `string` | n/a | yes |
| <a name="input_token_location"></a> [token_location](#input_token_location) | Location where the JWT token is expected (header or querystring) | `string` | `"header"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_authorizer_id"></a> [authorizer_id](#output_authorizer_id) | ID of the API Gateway authorizer |
| <a name="output_authorizer_name"></a> [authorizer_name](#output_authorizer_name) | Name of the API Gateway authorizer |
| <a name="output_invocation_role_arn"></a> [invocation_role_arn](#output_invocation_role_arn) | ARN of the IAM role used for API Gateway to invoke the authorizer |
| <a name="output_lambda_function_arn"></a> [lambda_function_arn](#output_lambda_function_arn) | ARN of the OIDC authorizer Lambda function |
| <a name="output_lambda_function_invoke_arn"></a> [lambda_function_invoke_arn](#output_lambda_function_invoke_arn) | Invoke ARN of the OIDC authorizer Lambda function |
| <a name="output_lambda_function_name"></a> [lambda_function_name](#output_lambda_function_name) | Name of the OIDC authorizer Lambda function |

<!-- END_TF_DOCS -->
