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
  nullable = false

  validation {
    condition     = length(var.endpoint_configuration.types) == 1
    error_message = "endpoint_configuration.types must contain exactly one value — AWS API Gateway supports a single endpoint type per REST API."
  }

  validation {
    condition     = alltrue([for t in var.endpoint_configuration.types : contains(["EDGE", "REGIONAL", "PRIVATE"], t)])
    error_message = "endpoint_configuration.types may only contain \"EDGE\", \"REGIONAL\", or \"PRIVATE\"."
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
  nullable    = false

  validation {
    condition     = contains(["0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237"], try(var.stage_config.cache_cluster.size, "0.5"))
    error_message = "If cache_cluster is provided, size must be one of: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237."
  }
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
  nullable    = false

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.logging_config.access_logs.retention_in_days
    )
    error_message = "logging_config.access_logs.retention_in_days must be a valid CloudWatch Logs retention value (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653). 0 means never expire."
  }

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.logging_config.execution_logs.retention_in_days
    )
    error_message = "logging_config.execution_logs.retention_in_days must be a valid CloudWatch Logs retention value (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653). 0 means never expire."
  }
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

  validation {
    condition = alltrue([
      for path, s in var.method_settings :
      s.logging_level == null || contains(["OFF", "ERROR", "INFO"], s.logging_level)
    ])
    error_message = "method_settings: logging_level must be one of \"OFF\", \"ERROR\", or \"INFO\"."
  }

  validation {
    condition = alltrue([
      for path, s in var.method_settings :
      s.unauthorized_cache_control_header_strategy == null || contains(["FAIL_WITH_403", "SUCCEED_WITH_RESPONSE_HEADER", "SUCCEED_WITHOUT_RESPONSE_HEADER"], s.unauthorized_cache_control_header_strategy)
    ])
    error_message = "method_settings: unauthorized_cache_control_header_strategy must be one of \"FAIL_WITH_403\", \"SUCCEED_WITH_RESPONSE_HEADER\", or \"SUCCEED_WITHOUT_RESPONSE_HEADER\"."
  }

  validation {
    condition = alltrue([
      for path, s in var.method_settings :
      s.throttling_rate_limit == null || s.throttling_rate_limit == -1 || s.throttling_rate_limit >= 0
    ])
    error_message = "method_settings: throttling_rate_limit must be -1 (throttling disabled) or a non-negative number."
  }

  validation {
    condition = alltrue([
      for path, s in var.method_settings :
      s.throttling_burst_limit == null || s.throttling_burst_limit == -1 || s.throttling_burst_limit >= 0
    ])
    error_message = "method_settings: throttling_burst_limit must be -1 (throttling disabled) or a non-negative integer."
  }

  validation {
    condition = alltrue([
      for path, s in var.method_settings :
      s.cache_ttl_in_seconds == null || (s.cache_ttl_in_seconds >= 0 && s.cache_ttl_in_seconds <= 3600)
    ])
    error_message = "method_settings: cache_ttl_in_seconds must be between 0 and 3600 seconds (the API Gateway cache TTL maximum)."
  }
}
