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
