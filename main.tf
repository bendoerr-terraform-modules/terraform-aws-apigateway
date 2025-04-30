module "label" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.5.0"
  context = var.context
  name    = var.name
}

resource "aws_api_gateway_rest_api" "this" {
  description = var.description
  name        = module.label.id
  tags        = module.label.tags

  body = var.openapi_config

  endpoint_configuration {
    types            = var.endpoint_configuration.types
    vpc_endpoint_ids = var.endpoint_configuration.vpc_endpoint_ids
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # This will trigger redeployment when the API definition changes
  triggers = {
    redeployment = sha256(jsonencode({
      openapi_config = aws_api_gateway_rest_api.this.body
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  count             = var.access_log_enabled ? 1 : 0
  name              = "/aws/apigateway/${module.label.id}-access-logs"
  tags              = module.label.tags
  retention_in_days = var.access_log_retention_in_days
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  description   = var.stage_description

  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size    = var.cache_cluster_enabled ? var.cache_cluster_size : null
  xray_tracing_enabled  = var.xray_tracing_enabled

  dynamic "access_log_settings" {
    for_each = var.access_log_enabled ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs[0].arn
      format          = replace(var.access_log_format, "\n", "")
    }
  }

  variables = var.stage_variables

  tags = module.label.tags
}

resource "aws_api_gateway_method_settings" "this" {
  for_each = var.method_settings

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = each.key

  settings {
    # Logging
    logging_level      = each.value.logging_level
    data_trace_enabled = each.value.data_trace_enabled
    metrics_enabled    = each.value.metrics_enabled

    # Throttling
    throttling_burst_limit = each.value.throttling_burst_limit
    throttling_rate_limit  = each.value.throttling_rate_limit

    # Caching
    cache_data_encrypted                       = each.value.cache_data_encrypted
    cache_ttl_in_seconds                       = each.value.cache_ttl_in_seconds
    caching_enabled                            = each.value.caching_enabled
    require_authorization_for_cache_control    = each.value.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = each.value.unauthorized_cache_control_header_strategy
  }
}

# CloudWatch Log Group for API Gateway execution logs
resource "aws_cloudwatch_log_group" "api_gateway_execution_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.this.id}/${var.stage_name}"
  retention_in_days = var.execution_log_retention_in_days
  tags              = module.label.tags
}
