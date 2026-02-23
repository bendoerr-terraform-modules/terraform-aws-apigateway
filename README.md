<br/>
<p align="center">
  <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/raw/main/docs/logo-dark.png">
      <img src="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/raw/main/docs/logo-light.png" alt="Logo">
    </picture>
  </a>

<h3 align="center">Ben's Terraform AWS API Gateway Module</h3>

<p align="center">
    This is how I do it.
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway"><strong>Explore the docs »</strong></a>
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/issues">Report Bug</a>
    .
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/issues">Request Feature</a>
  </p>
</p>

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-apigateway?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/graphs/contributors)
[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-apigateway?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/issues)
[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-apigateway?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/pulls)
[<img alt="GitHub workflow: Terratest" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-apigateway/test.yml?logo=githubactions&label=terratest">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/actions/workflows/test.yml)
[<img alt="GitHub workflow: Linting" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-apigateway/lint.yml?logo=githubactions&label=linting">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/actions/workflows/lint.yml)
[<img alt="GitHub tag (with filter)" src="https://img.shields.io/github/v/tag/bendoerr-terraform-modules/terraform-aws-apigateway?filter=v*&label=latest%20tag&logo=terraform">](https://registry.terraform.io/modules/bendoerr-terraform-modules/apigateway/aws/latest)
[<img alt="OSSF-Scorecard Score" src="https://img.shields.io/ossf-scorecard/github.com/bendoerr-terraform-modules/terraform-aws-apigateway?logo=securityscorecard&label=ossf%20scorecard&link=https%3A%2F%2Fsecurityscorecards.dev%2Fviewer%2F%3Furi%3Dgithub.com%2Fbendoerr-terraform-modules%2Fterraform-aws-apigateway">](https://securityscorecards.dev/viewer/?uri=github.com/bendoerr-terraform-modules/terraform-aws-apigateway)
[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-apigateway?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/blob/main/LICENSE.txt)

## About The Project

This Terraform module creates an AWS API Gateway REST API with comprehensive configuration options including CloudWatch
logging, custom domains, method settings, and OpenAPI specification support.

### Why REST API Gateway (v1) Instead of HTTP API Gateway?

This module uses the REST API Gateway (v1) instead of HTTP API Gateway because it offers greater flexibility, security
features like WAF integration, and advanced customization options. While slightly more expensive, REST API Gateway
provides the production-grade controls needed for modern APIs.

## Usage

```hcl
module "api_gateway" {
  source = "bendoerr-terraform-modules/apigateway/aws"

  context     = module.context
  name        = "example-api"
  description = "Example API Gateway"

  # OpenAPI specification
  openapi_config = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "Example API"
      version = "1.0"
    }
    # ... rest of OpenAPI spec ...
  })

  # Stage configuration (all attributes optional with sensible defaults)
  stage_config = {
    name        = "v1"
    description = "Version 1"
  }

  # Logging configuration (all attributes optional)
  logging_config = {
    access_logs = {
      retention_in_days = 14
    }
    execution_logs = {
      retention_in_days = 14
    }
  }

  # Method settings (object attributes are optional with defaults)
  method_settings = {
    "*/*" = {
      logging_level   = "INFO"
      metrics_enabled = true
    }
    "api/v1/users/GET" = {
      logging_level        = "ERROR"
      throttling_rate_limit = 100
    }
  }
}
```

## Upgrading

### v0.x → v1.0 (Breaking Change)

Individual stage and logging variables have been consolidated into `stage_config` and `logging_config` objects:

| Old Variable | New Path |
|---|---|
| `stage_name` | `stage_config.name` |
| `stage_description` | `stage_config.description` |
| `cache_cluster_enabled` | `stage_config.cache_cluster.enabled` |
| `cache_cluster_size` | `stage_config.cache_cluster.size` |
| `xray_tracing_enabled` | `stage_config.xray_tracing_enabled` |
| `stage_variables` | `stage_config.variables` |
| `access_log_enabled` | `logging_config.access_logs.enabled` |
| `access_log_format` | `logging_config.access_logs.format` |
| `access_log_retention_in_days` | `logging_config.access_logs.retention_in_days` |
| `execution_log_retention_in_days` | `logging_config.execution_logs.retention_in_days` |

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_label"></a> [label](#module\_label) | bendoerr-terraform-modules/label/null | 0.5.0 |

### Resources

| Name | Type |
|------|------|
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_method_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_cloudwatch_log_group.api_gateway_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.api_gateway_execution_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module. | <pre>object({<br>    attributes     = list(string)<br>    dns_namespace  = string<br>    environment    = string<br>    instance       = string<br>    instance_short = string<br>    namespace      = string<br>    region         = string<br>    region_short   = string<br>    role           = string<br>    role_short     = string<br>    project        = string<br>    tags           = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Description of the API Gateway REST API | `string` | `null` | no |
| <a name="input_endpoint_configuration"></a> [endpoint\_configuration](#input\_endpoint\_configuration) | Configuration block defining API endpoint configuration including endpoint type and VPC endpoint IDs | <pre>object({<br>    types            = list(string)<br>    vpc_endpoint_ids = optional(list(string))<br>  })</pre> | <pre>{<br>  "types": [<br>    "EDGE"<br>  ]<br>}</pre> | no |
| <a name="input_logging_config"></a> [logging\_config](#input\_logging\_config) | CloudWatch logging configuration for API Gateway access and execution logs. | <pre>object({<br>    access_logs = optional(object({<br>      enabled           = optional(bool, true)<br>      format            = optional(string)<br>      retention_in_days = optional(number, 7)<br>    }), {})<br>    execution_logs = optional(object({<br>      retention_in_days = optional(number, 7)<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_method_settings"></a> [method\_settings](#input\_method\_settings) | Map of method paths to their settings. Each key is a method path (format: resource\_path/http\_method, where * can be used as a wildcard), and each value is a map of settings. An empty map disables method settings. | <pre>map(object({<br>    logging_level                              = optional(string, "INFO")<br>    data_trace_enabled                         = optional(bool, false)<br>    metrics_enabled                            = optional(bool, true)<br>    throttling_burst_limit                     = optional(number, 5000)<br>    throttling_rate_limit                      = optional(number, 10000)<br>    caching_enabled                            = optional(bool, false)<br>    cache_ttl_in_seconds                       = optional(number, 300)<br>    cache_data_encrypted                       = optional(bool, true)<br>    require_authorization_for_cache_control    = optional(bool, true)<br>    unauthorized_cache_control_header_strategy = optional(string, "SUCCEED_WITH_RESPONSE_HEADER")<br>  }))</pre> | <pre>{<br>  "*/*": {<br>    "cache_data_encrypted": true,<br>    "cache_ttl_in_seconds": 300,<br>    "caching_enabled": false,<br>    "data_trace_enabled": false,<br>    "logging_level": "INFO",<br>    "metrics_enabled": true,<br>    "require_authorization_for_cache_control": true,<br>    "throttling_burst_limit": 5000,<br>    "throttling_rate_limit": 10000,<br>    "unauthorized_cache_control_header_strategy": "SUCCEED_WITH_RESPONSE_HEADER"<br>  }<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module. | `string` | `"thing"` | no |
| <a name="input_openapi_config"></a> [openapi\_config](#input\_openapi\_config) | JSON or YAML string that defines the API using OpenAPI specification | `string` | `null` | no |
| <a name="input_stage_config"></a> [stage\_config](#input\_stage\_config) | API Gateway stage configuration including caching and tracing settings. | <pre>object({<br>    name                 = optional(string, "api")<br>    description          = optional(string)<br>    variables            = optional(map(string), {})<br>    xray_tracing_enabled = optional(bool, false)<br>    cache_cluster = optional(object({<br>      enabled = optional(bool, false)<br>      size    = optional(string, "0.5")<br>    }), {})<br>  })</pre> | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group for API Gateway access logs |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group for API Gateway access logs |
| <a name="output_deployment_id"></a> [deployment\_id](#output\_deployment\_id) | ID of the API Gateway deployment |
| <a name="output_execution_log_group_arn"></a> [execution\_log\_group\_arn](#output\_execution\_log\_group\_arn) | ARN of the CloudWatch log group for API Gateway execution logs |
| <a name="output_execution_log_group_name"></a> [execution\_log\_group\_name](#output\_execution\_log\_group\_name) | Name of the CloudWatch log group for API Gateway execution logs |
| <a name="output_id"></a> [id](#output\_id) | The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module. |
| <a name="output_method_settings_id"></a> [method\_settings\_id](#output\_method\_settings\_id) | IDs of the API Gateway method settings |
| <a name="output_name"></a> [name](#output\_name) | The provided name given to the module. |
| <a name="output_rest_api_arn"></a> [rest\_api\_arn](#output\_rest\_api\_arn) | ARN of the REST API |
| <a name="output_rest_api_execution_arn"></a> [rest\_api\_execution\_arn](#output\_rest\_api\_execution\_arn) | Execution ARN part to be used in lambda\_permission's source\_arn |
| <a name="output_rest_api_id"></a> [rest\_api\_id](#output\_rest\_api\_id) | ID of the REST API |
| <a name="output_rest_api_name"></a> [rest\_api\_name](#output\_rest\_api\_name) | Name of the REST API |
| <a name="output_rest_api_root_resource_id"></a> [rest\_api\_root\_resource\_id](#output\_rest\_api\_root\_resource\_id) | Resource ID of the REST API's root |
| <a name="output_stage_arn"></a> [stage\_arn](#output\_stage\_arn) | ARN of the API Gateway stage |
| <a name="output_stage_execution_arn"></a> [stage\_execution\_arn](#output\_stage\_execution\_arn) | Execution ARN to be used in permissions policy |
| <a name="output_stage_id"></a> [stage\_id](#output\_stage\_id) | ID of the API Gateway stage |
| <a name="output_stage_invoke_url"></a> [stage\_invoke\_url](#output\_stage\_invoke\_url) | URL to invoke the API pointing to the stage |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | Name of the API Gateway stage |
| <a name="output_tags"></a> [tags](#output\_tags) | The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module. |
<!-- END_TF_DOCS -->

## Roadmap

[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-apigateway?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/issues)

See the [open issues](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/issues) for a list of
proposed features (and known issues).

## Contributing

[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-apigateway?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/pulls)

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any
contributions you make are **greatly appreciated**.

- If you have suggestions for adding or removing projects, feel free to
  [open an issue](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/issues/new) to discuss it,
  or directly create a pull request after you edit the _README.md_ file with necessary changes.
- Please make sure you check your spelling and grammar.
- Create individual PR for each suggestion.

### Creating A Pull Request

1. Fork the Project
1. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
1. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
1. Push to the Branch (`git push origin feature/AmazingFeature`)
1. Open a Pull Request

## License

[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-apigateway?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/blob/main/LICENSE.txt)

Distributed under the MIT License. See
[LICENSE](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/blob/main/LICENSE.txt) for more
information.

## Authors

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-apigateway?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/graphs/contributors)

- **Benjamin R. Doerr** - _Terraformer_ - [Benjamin R. Doerr](https://github.com/bendoerr/) - _Built Ben's Terraform Modules_

## Supported Versions

Only the latest tagged version is supported.

## Reporting a Vulnerability

See [SECURITY.md](SECURITY.md).

## Acknowledgements

- [ShaanCoding (ReadME Generator)](https://github.com/ShaanCoding/ReadME-Generator)
- [OpenSSF - Helping me follow best practices](https://openssf.org/)
- [StepSecurity - Helping me follow best practices](https://app.stepsecurity.io/)
- [Infracost - Better than AWS Calculator](https://www.infracost.io/)
