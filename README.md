<br/>
<p align="center">
  <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/raw/main/docs/logo-dark.png">
      <img src="https://github.com/bendoerr-terraform-modules/terraform-aws-apigateway/raw/main/docs/logo-light.png" alt="Logo">
    </picture>
  </a>

<h3 align="center">Ben's Terraform Module Template Repo</h3>

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
[<img alt="GitHub tag (with filter)" src="https://img.shields.io/github/v/tag/bendoerr-terraform-modules/terraform-aws-apigateway?filter=v*&label=latest%20tag&logo=terraform">](https://registry.terraform.io/modules/bendoerr-terraform-modules/terraform-aws-apigateway/aws/latest)
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
  source = "bendoerr-terraform-modules/api-gateway/aws"

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

  # API Gateway configuration
  stage_name        = "v1"
  stage_description = "Version 1"

  # Enable access logs with CloudWatch
  access_log_enabled = true
  log_retention_days = 14

  # Method settings - single path approach (legacy)
  method_settings_enabled = true
  logging_level           = "INFO"
  metrics_enabled         = true

  # OR

  # Method settings - multiple paths approach (recommended)
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

<!-- BEGIN_TF_DOCS -->

### Requirements

| Name | Version |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 5.0 |

### Providers

| Name | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.64.0 |

### Modules

| Name | Source | Version |
| -------------------------------------------------- | ------------------------------------- | ------- |
| <a name="module_label"></a> [label](#module_label) | bendoerr-terraform-modules/label/null | 0.4.2 |

### Resources

| Name | Type |
| -------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | :------: |
| <a name="input_context"></a> [context](#input_context) | Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module. | <pre>object({<br> attributes = list(string)<br> dns_namespace = string<br> environment = string<br> instance = string<br> instance_short = string<br> namespace = string<br> region = string<br> region_short = string<br> role = string<br> role_short = string<br> project = string<br> tags = map(string)<br> })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input_name) | A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module. | `string` | `"thing"` | no |

### Outputs

| Name | Description |
| -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| <a name="output_caller_identity"></a> [caller_identity](#output_caller_identity) | This can be removed if it is not needed |
| <a name="output_id"></a> [id](#output_id) | The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module. |
| <a name="output_name"></a> [name](#output_name) | The provided name given to the module. |
| <a name="output_tags"></a> [tags](#output_tags) | The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module. |

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
