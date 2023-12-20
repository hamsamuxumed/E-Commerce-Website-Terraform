// Naming

variable "bucket_name" {
  description = "Name of the bucket to be created"
  type        = string
}


// Control of behaviour

variable "object_expiration_days" {
  description = "Number of days after which objects will be automatically deleted"
  type        = number
  default     = 30
}


// For tags

variable "tags" {
  description = "Set of tags to be applied to all supported resources"
  type        = map(string)
}
