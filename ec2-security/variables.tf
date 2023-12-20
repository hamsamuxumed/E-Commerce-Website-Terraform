variable "name" {
  description = "Name (kebab-case-format recommended) that will be used to prefix resource names."
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-2"
}

variable "tags" {
  description = "Set of tags to be applied to all supported resources."
  type        = map(string)
}

variable "vpc_id" {
  description = "ID of the VPC to contain the resources."
  type        = string
}

variable "ec2_web_roles" {
  description = "List of different types of web servers that are needed. IE Frontend/Backend"
  type        = list(string)
  default     = []
}

variable "ec2_misc_roles" {
  description = "List of different types of web servers that are needed. IE Frontend/Backend"
  type        = list(string)
  default     = []
}