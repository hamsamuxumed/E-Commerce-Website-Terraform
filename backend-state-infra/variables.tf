// Naming

variable "bucket_name" {
  description = "Name of the bucket to be created"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the bucket to be created"
  type        = string
  default     = "terraform-lock-table"
}

// For tags

variable "tags" {
  description = "Map of tags to be applied to all supported resources"
  type        = map(string)
}
