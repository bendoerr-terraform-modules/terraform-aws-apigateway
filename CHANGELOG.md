# Changelog

## Unreleased

### ✨ Added

- New `stage_config` variable: groups `stage_name`, `stage_description`, `cache_cluster_enabled`, `cache_cluster_size`, `xray_tracing_enabled`, and `stage_variables` into a single object with optional attributes.
- New `logging_config` variable: groups `access_log_enabled`, `access_log_format`, `access_log_retention_in_days`, and `execution_log_retention_in_days` into a single object with optional attributes.

### ⚠️ Deprecated

- `stage_name` — use `stage_config.name`
- `stage_description` — use `stage_config.description`
- `cache_cluster_enabled` — use `stage_config.cache_cluster.enabled`
- `cache_cluster_size` — use `stage_config.cache_cluster.size`
- `xray_tracing_enabled` — use `stage_config.xray_tracing_enabled`
- `stage_variables` — use `stage_config.variables`
- `access_log_enabled` — use `logging_config.access_logs.enabled`
- `access_log_format` — use `logging_config.access_logs.format`
- `access_log_retention_in_days` — use `logging_config.access_logs.retention_in_days`
- `execution_log_retention_in_days` — use `logging_config.execution_logs.retention_in_days`

### Migration Guide

Replace individual variables with the grouped equivalents:

```hcl
# Before
module "api_gateway" {
  source = "bendoerr-terraform-modules/apigateway/aws"

  stage_name             = "v1"
  stage_description      = "Version 1"
  cache_cluster_enabled  = true
  cache_cluster_size     = "1.6"
  xray_tracing_enabled   = true
  access_log_enabled     = true
  access_log_retention_in_days    = 14
  execution_log_retention_in_days = 14
}

# After
module "api_gateway" {
  source = "bendoerr-terraform-modules/apigateway/aws"

  stage_config = {
    name        = "v1"
    description = "Version 1"
    cache_cluster = {
      enabled = true
      size    = "1.6"
    }
    xray_tracing_enabled = true
  }

  logging_config = {
    access_logs = {
      enabled           = true
      retention_in_days = 14
    }
    execution_logs = {
      retention_in_days = 14
    }
  }
}
```

The deprecated variables still work and take precedence over `stage_config`/`logging_config` when set, allowing a gradual migration. They will be removed in the next major version.
