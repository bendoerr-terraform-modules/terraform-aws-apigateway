output "caller_identity" {
  value       = data.aws_caller_identity.this.arn
  description = "This can be removed if it is not needed"
}

output "id" {
  value       = module.label.id
  description = "The normalized ID from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "tags" {
  value       = module.label.tags
  description = "The normalized tags from the 'bendoerr-terraform-modules/terraform-null-label' module."
}

output "name" {
  value       = var.name
  description = "The provided name given to the module."
}
