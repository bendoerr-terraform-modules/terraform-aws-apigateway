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

variable "enabled" {
  type        = bool
  description = "Whether to enable a custom domain name for the API Gateway"
  default     = false
}

variable "domain_name" {
  type        = string
  description = "Custom domain name for the API Gateway"
  default     = null
}

variable "certificate_type" {
  type        = string
  description = "Type of certificate for the custom domain. Valid values: EDGE, REGIONAL"
  default     = "REGIONAL"
  validation {
    condition     = contains(["EDGE", "REGIONAL"], var.certificate_type)
    error_message = "Valid values for certificate_type are EDGE or REGIONAL."
  }
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate to use for the custom domain"
  default     = null
}

variable "security_policy" {
  type        = string
  description = "TLS security policy for the custom domain. Valid values: TLS_1_0, TLS_1_2"
  default     = "TLS_1_2"
}

variable "endpoint_type" {
  type        = string
  description = "Endpoint type for the domain name. Valid values: EDGE, REGIONAL"
  default     = "REGIONAL"
}

variable "create_base_path_mapping" {
  type        = bool
  description = "Whether to create a base path mapping for the custom domain"
  default     = true
}

variable "base_path" {
  type        = string
  description = "Base path to map the API under the domain (empty string for root)"
  default     = ""
}

variable "api_id" {
  type        = string
  description = "ID of the API Gateway REST API"
}

variable "stage_name" {
  type        = string
  description = "Name of the API Gateway stage"
}
