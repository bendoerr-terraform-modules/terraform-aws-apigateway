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
  default     = "oidc-authorizer"
  description = "A descriptive but short name used for labels by the 'bendoerr-terraform-modules/terraform-null-label' module."
  nullable    = false
}

variable "rest_api_id" {
  type        = string
  description = "ID of the API Gateway REST API to attach the authorizer to"
}

variable "rest_api_execution_arn" {
  type        = string
  description = "Execution ARN of the API Gateway REST API"
}

# OIDC Authorizer Configuration
variable "jwks_uri" {
  type        = string
  description = "The URL of the OIDC provider JWKS (Endpoint providing public keys for verification)."
  nullable    = false
}

variable "issuer_url" {
  type        = string
  description = "URL of the OIDC issuer (e.g., https://accounts.google.com)"
}

variable "audience" {
  type        = string
  description = "Expected audience for the tokens (client ID of your application)"
}

variable "token_location" {
  type        = string
  default     = "header"
  description = "Location where the JWT token is expected (header or querystring)"
  validation {
    condition     = contains(["header", "querystring"], var.token_location)
    error_message = "token_location must be either 'header' or 'querystring'"
  }
}

variable "authorization_header" {
  type        = string
  default     = "Authorization"
  description = "Name of the header or query parameter containing the token"
}

variable "identity_validation_expression" {
  type        = string
  default     = null
  description = "Regular expression to validate the token format (optional)"
}

variable "cache_ttl" {
  type        = number
  default     = 300
  description = "Time to live in seconds for the authorizer cache"
}

variable "log_level" {
  type        = string
  default     = "error"
  description = "Log level for the Lambda function (debug, info, warn, error)"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "log_level must be one of: debug, info, warn, error"
  }
}

variable "lambda_zip_path" {
  type        = string
  default     = null
  description = "Path to a custom Lambda ZIP file (if not provided, will download from GitHub)"
}

variable "oidc_authorizer_version" {
  type        = string
  default     = "0.1.2"
  description = "Version of oidc-authorizer to use (only used when downloading from GitHub)"
}
