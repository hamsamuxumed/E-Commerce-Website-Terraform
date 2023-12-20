variable "lookup_ami" {
  type        = bool
  description = "To avoid a chicken and egg situation, this flag allows the first AMI to be created before automatically updating it."
  default     = true
}

variable "aws_region" {
  type        = string
  description = "Region for AWS Resources"
  default     = "eu-west-2"
}

variable "key_name" {
  description = "Key name for AWS launch template"
  type        = string
}

variable "image_id" {
  description = "AMI to use in launch template"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet ids to use in launch template"
  type        = list(string)
}

# variable "availability_zones" {
#   description = "AZs to use in launch template"
#   type        = list(string)
# }

variable "security_group_ids" {
  description = "Security group ID to use in launch template"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type to use in launch template"
  type        = string
}

variable "user_data" {
  description = "Path to user_data script"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile for launch template"
  type        = string
  default     = "eu-west-2"
}

variable "ami_identifier" {
  description = "Extra tag to filter on for AMI"
  type        = string
}

variable "target_group_arn" {
  description = "Target Group ARNs"
  type        = string
  default     = ""
}

variable "desired_capacity" {
  description = "Target Group ARNs"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Target Group ARNs"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Target Group ARNs"
  type        = number
  default     = 1
}

// For tags

variable "tags" {
  description = "Map of tags to be applied to all supported resources"
  type        = map(string)
}
