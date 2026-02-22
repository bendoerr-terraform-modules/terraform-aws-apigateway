locals {
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

  access_log_format  = coalesce(var.logging_config.access_logs.format, local.default_access_log_format)
  access_log_enabled = var.logging_config.access_logs.enabled
}
