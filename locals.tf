# Backward compatibility: deprecated individual variables override stage_config/logging_config
# when explicitly set (non-null). This allows existing users to migrate gradually.

locals {
  # Default access log format used when neither new nor old variable provides one
  default_access_log_format = <<-EOF
    {
      "requestId":"$context.requestId",
      "ip":"$context.identity.sourceIp",
      "requestTime":"$context.requestTime",
      "httpMethod":"$context.httpMethod",
      "resourcePath":"$context.resourcePath",
      "status":"$context.status",
      "protocol":"$context.protocol",
      "responseLength":"$context.responseLength",
      "integrationError":"$context.integrationErrorMessage",
      "authorizerError":"$context.authorizer.error"
    }
  EOF

  # Resolved stage configuration: deprecated vars take precedence when set
  stage = {
    name                  = coalesce(var.stage_name, var.stage_config.name)
    description           = var.stage_description != null ? var.stage_description : var.stage_config.description
    variables             = var.stage_variables != null ? var.stage_variables : var.stage_config.variables
    cache_cluster_enabled = var.cache_cluster_enabled != null ? var.cache_cluster_enabled : var.stage_config.cache_cluster.enabled
    cache_cluster_size    = var.cache_cluster_size != null ? var.cache_cluster_size : var.stage_config.cache_cluster.size
    xray_tracing_enabled  = var.xray_tracing_enabled != null ? var.xray_tracing_enabled : var.stage_config.xray_tracing_enabled
  }

  # Resolved logging configuration: deprecated vars take precedence when set
  logging = {
    access_log_enabled              = var.access_log_enabled != null ? var.access_log_enabled : var.logging_config.access_logs.enabled
    access_log_format               = var.access_log_format != null ? var.access_log_format : coalesce(var.logging_config.access_logs.format, local.default_access_log_format)
    access_log_retention_in_days    = var.access_log_retention_in_days != null ? var.access_log_retention_in_days : var.logging_config.access_logs.retention_in_days
    execution_log_retention_in_days = var.execution_log_retention_in_days != null ? var.execution_log_retention_in_days : var.logging_config.execution_logs.retention_in_days
  }
}
