// Naming and tagging

variable "name" {
  description = "Name (kebab-case-format recommended) that will be used to prefix resource names."
  type        = string
}

variable "tags" {
  description = "Set of tags to be applied to all supported resources."
  type        = map(string)
}

// Configuration

variable "edition" {
  description = "SQL Server edition, e.g. 'ex' for Express, 'ee' for Enterprise Edition"
  type        = string
}

variable "engine_version" {
  description = "Major version of the engine, e.g. 14.00"
  type        = string
}

variable "instance_class" {
  description = "RDS instance type, e.g. db.t2.micro"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi AZ for high availability"
  type        = bool
  default     = false
}

variable "initial_storage_size" {
  description = "Initial size of the storage volume, in GiB."
  type        = number
  default     = 20
}

variable "maximum_storage_size" {
  description = "Maximum size of the storage volume. To prevent storage autoscaling, set to null."
  type        = number
  default     = 1000
}

variable "role_for_native_backups" {
  description = "IAM role for RDS to use when working with native backups. Typically this will grant access to the required S3 buckets."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC to contain the resources."
  type        = string
}

variable "subnets" {
  description = "List of IDs of subnets for the RDS DB subnet group."
  type        = list(string)
}

variable "access_security_group" {
  description = "ID of a security group whose members can access the SQL Server instance."
  type        = string
}

variable "kms_key_id" {
  description = "ID of a KMS key to be used for encrypting the EBS volume and snapshots (optional)."
  type        = string
  default     = null
}

variable "override_names" {
  description = "Map which specifies name overrides, useful when importing existing infrastructure. See README.md."
  type        = map(string)
  default     = {}
}


// Monitoring

variable "production_monitoring" {
  description = "Enabled monitoring recommended for production use (1-minute metrics and Performance Insights)"
  type        = bool
  default     = false
}

variable "sns_urgent_priority" {
  description = "ARN of an SNS topic to receive urgent notifications (optional)"
  type        = string
  default     = null
}

variable "sns_high_priority" {
  description = "ARN of an SNS topic to receive high-priority notifications (optional)"
  type        = string
  default     = null
}

variable "sns_low_priority" {
  description = "ARN of an SNS topic to receive low-priority notifications (optional)"
  type        = string
  default     = null
}

variable "read_latency_threshold" {
  description = "Threshold in seconds for warnings of high read latency, or null to disable"
  type        = number
  default     = 1.0
}

variable "write_latency_threshold" {
  description = "Threshold in seconds for warnings of high write latency, or null to disable"
  type        = number
  default     = 1.0
}

variable "disk_queue_depth_threshold" {
  description = "Threshold for warnings of high disk queue depths, or null to disable"
  type        = number
  default     = 1000
}
