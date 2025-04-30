variable "context" {
  type = object({
    attributes     = list(string)
    dns_namespace  = string
    environment    = string
    instance       = string
    instance_short = string
    namespace      = string
    region         = string
    region_short   = string
    role           = string
    role_short     = string
    project        = string
    tags           = map(string)
  })
  description = "Shared context from the 'bendoerr-terraform-modules/terraform-null-context' module."
}

variable "name" {
  type        = string
  default     = "thing"
  description = "A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module."
  nullable    = false
}

variable "description" {
  type        = string
  description = "Description of the API Gateway REST API"
  default     = null
}

variable "openapi_config" {
  type        = string
  description = "JSON or YAML string that defines the API using OpenAPI specification"
  default     = null
}

variable "endpoint_configuration" {
  type = object({
    types            = list(string)
    vpc_endpoint_ids = optional(list(string))
  })
  description = "Configuration block defining API endpoint configuration including endpoint type and VPC endpoint IDs"
  default = {
    types = ["EDGE"]
  }
}

variable "stage_name" {
  type        = string
  description = "Name of the stage for API Gateway deployment"
  default     = "api"
}

variable "stage_description" {
  type        = string
  description = "Description of the API Gateway stage"
  default     = null
}

variable "cache_cluster_enabled" {
  type        = bool
  description = "Whether a cache cluster is enabled for the stage"
  default     = false
}

variable "cache_cluster_size" {
  type        = string
  description = "Size of the cache cluster for the stage, if enabled. Allowed values include 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237"
  default     = "0.5"
}

variable "xray_tracing_enabled" {
  type        = bool
  description = "Whether active tracing with X-ray is enabled for the stage"
  default     = false
}

variable "access_log_enabled" {
  type        = bool
  description = "Whether to enable access logging for the API Gateway stage"
  default     = true
}

variable "access_log_format" {
  type        = string
  description = "Format of the access logs for the API Gateway stage"
  default     = <<EOF
{
  "requestId":"$context.requestId",
  "ip":"$context.identity.sourceIp",
  "requestTime":"$context.requestTime",
  "httpMethod":"$context.httpMethod",
  "routeKey":"$context.routeKey",
  "status":"$context.status",
  "protocol":"$context.protocol",
  "responseLength":"$context.responseLength",
  "integrationError":"$context.integrationErrorMessage",
  "authorizerError":"$context.authorizer.error"
}
EOF
}

variable "access_log_retention_in_days" {
  type        = number
  description = "Number of days to retain API Gateway access logs"
  default     = 7
}

variable "execution_log_retention_in_days" {
  type        = number
  description = "Number of days to retain API Gateway execution logs"
  default     = 7
}

variable "stage_variables" {
  type        = map(string)
  description = "Map of stage variables to be used in the API Gateway stage"
  default     = {}
}

variable "method_settings" {
  type = map(object({
    logging_level                              = optional(string, "INFO")
    data_trace_enabled                         = optional(bool, false)
    metrics_enabled                            = optional(bool, true)
    throttling_burst_limit                     = optional(number, 5000)
    throttling_rate_limit                      = optional(number, 10000)
    caching_enabled                            = optional(bool, false)
    cache_ttl_in_seconds                       = optional(number, 300)
    cache_data_encrypted                       = optional(bool, true)
    require_authorization_for_cache_control    = optional(bool, true)
    unauthorized_cache_control_header_strategy = optional(string, "SUCCEED_WITH_RESPONSE_HEADER")
  }))
  description = "Map of method paths to their settings. Each key is a method path (format: resource_path/http_method, where * can be used as a wildcard), and each value is a map of settings. An empty map disables method settings."
  default = {
    "*/*" = {
      logging_level                              = "INFO"
      data_trace_enabled                         = false
      metrics_enabled                            = true
      throttling_burst_limit                     = 5000
      throttling_rate_limit                      = 10000
      caching_enabled                            = false
      cache_ttl_in_seconds                       = 300
      cache_data_encrypted                       = true
      require_authorization_for_cache_control    = true
      unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"
    }
  }
}
