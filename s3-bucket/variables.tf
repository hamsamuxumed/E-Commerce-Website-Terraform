variable "bucket_name" {
  description = "Name of the bucket to be created"
  type        = string
}

variable "tags" {
  description = "Set of tags to be applied to all supported resources"
  type        = map(string)
}
