// Naming and tagging


variable "name" {
  description = "Name (kebab-case-format recommended) that will be used to prefix resource names."
  type        = string
}

variable "tags" {
  description = "Set of tags to be applied to all supported resources"
  type        = map(string)
}

// Configuration

variable "subnets" {
  description = "List of IDs of subnets to create a mount target in. Must all be in the same VPC."
  type        = list(string)
}

variable "access_security_group" {
  description = "ID of a security group whose members can access the EFS volume"
  type        = string
}

// Special configuration

variable "override_security_group_name" {
  description = "Explicit name for the security group, overriding the module's default name"
  type        = string
  default     = null
}

variable "override_security_group_description" {
  description = "Explicit description for the security group, overriding the module's default description"
  type        = string
  default     = null
}
