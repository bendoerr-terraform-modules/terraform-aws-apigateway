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

#
# Stage Configuration (grouped)
#

variable "stage_config" {
  type = object({
    name        = optional(string, "api")
    description = optional(string)
    variables   = optional(map(string), {})
    cache_cluster = optional(object({
      enabled = optional(bool, false)
      size    = optional(string, "0.5")
    }), {})
    xray_tracing_enabled = optional(bool, false)
  })
  description = "API Gateway stage configuration including caching and tracing settings. Replaces the individual stage_name, stage_description, cache_cluster_enabled, cache_cluster_size, xray_tracing_enabled, and stage_variables variables."
  default     = {}
}

#
# Logging Configuration (grouped)
#

variable "logging_config" {
  type = object({
    access_logs = optional(object({
      enabled           = optional(bool, true)
      format            = optional(string)
      retention_in_days = optional(number, 7)
    }), {})
    execution_logs = optional(object({
      retention_in_days = optional(number, 7)
    }), {})
  })
  description = "CloudWatch logging configuration for API Gateway access and execution logs. Replaces the individual access_log_enabled, access_log_format, access_log_retention_in_days, and execution_log_retention_in_days variables."
  default     = {}
}

#
# Deprecated variables - kept for backward compatibility
# These will be removed in the next major version.
# Use stage_config and logging_config instead.
#

variable "stage_name" {
  type        = string
  description = "DEPRECATED: Use stage_config.name instead. Name of the stage for API Gateway deployment."
  default     = null
}

variable "stage_description" {
  type        = string
  description = "DEPRECATED: Use stage_config.description instead. Description of the API Gateway stage."
  default     = null
}

variable "cache_cluster_enabled" {
  type        = bool
  description = "DEPRECATED: Use stage_config.cache_cluster.enabled instead. Whether a cache cluster is enabled for the stage."
  default     = null
}

variable "cache_cluster_size" {
  type        = string
  description = "DEPRECATED: Use stage_config.cache_cluster.size instead. Size of the cache cluster for the stage."
  default     = null
}

variable "xray_tracing_enabled" {
  type        = bool
  description = "DEPRECATED: Use stage_config.xray_tracing_enabled instead. Whether active tracing with X-ray is enabled for the stage."
  default     = null
}

variable "access_log_enabled" {
  type        = bool
  description = "DEPRECATED: Use logging_config.access_logs.enabled instead. Whether to enable access logging."
  default     = null
}

variable "access_log_format" {
  type        = string
  description = "DEPRECATED: Use logging_config.access_logs.format instead. Format of the access logs."
  default     = null
}

variable "access_log_retention_in_days" {
  type        = number
  description = "DEPRECATED: Use logging_config.access_logs.retention_in_days instead. Number of days to retain access logs."
  default     = null
}

variable "execution_log_retention_in_days" {
  type        = number
  description = "DEPRECATED: Use logging_config.execution_logs.retention_in_days instead. Number of days to retain execution logs."
  default     = null
}

variable "stage_variables" {
  type        = map(string)
  description = "DEPRECATED: Use stage_config.variables instead. Map of stage variables."
  default     = null
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
