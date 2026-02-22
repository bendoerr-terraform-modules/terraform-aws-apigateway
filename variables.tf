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

variable "stage_config" {
  type = object({
    name                 = optional(string, "api")
    description          = optional(string)
    variables            = optional(map(string), {})
    xray_tracing_enabled = optional(bool, false)
    cache_cluster = optional(object({
      enabled = optional(bool, false)
      size    = optional(string, "0.5")
    }), {})
  })
  description = "API Gateway stage configuration including caching and tracing settings."
  default     = {}
}

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
  description = "CloudWatch logging configuration for API Gateway access and execution logs."
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
