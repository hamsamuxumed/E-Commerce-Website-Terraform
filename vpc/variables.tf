// Control of behaviour

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string

  # Experimental feature since Terraform 0.12.20; expected GA in 0.13
  # https://www.terraform.io/docs/configuration/variables.html#custom-validation-rules
  #validation {
  #  condition     = can(regex("^\d{,3}.\d{,3}.\d{,3}.\d{,3}/[0-3][0-9]$"))
  #  error_message = "Argument \"vpc_cidr_block\" must be an IPv4 CIDR prefix in the standard CIDR prefix notation."
  #}
}

variable "az_count" {
  default = 2
}

variable "create_private_subnets" {
  description = "True (default) to create public and private subnets; false to create public subnets only"
  default     = true
  type        = bool
}

variable "create_private_nat_gateways" {
  default = false
}

variable "vpc_flow_logs_s3_bucket_name" {
  description = "S3 Bucket name in which to write VPC flow logs, or disabled if blank"
}

// For tags and naming

variable "name" {
  description = "Name (kebab-case-format recommended) that will be used to prefix resource names."
  type        = string
}

variable "tags" {
  description = "Map of tags to be applied to all supported resources"
  type        = map(string)
}

