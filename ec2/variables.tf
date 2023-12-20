// Naming and tagging

variable "name" {
  description = "Name (kebab-case-format recommended) that will be used to prefix resource names."
  type        = string
}

variable "override_names" {
  description = "Map which specifies name overrides, useful when importing existing infrastructure. See README.md."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Set of tags to be applied to all supported resources."
  type        = map(string)
}

variable "schedule" {
  description = "Schedule tags to turn off and on resources"
  type        = map(string)
  default     = {}
}
variable "serveruse" {
  description = "Use of the server such as frontend or services"
  type        = string
}

// Configuration
variable "ami" {
  description = "Name of AMI such as /aws/service/ami-windows-latest/Windows_Server-2019-English-Full-Base"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to contain the resources."
  type        = string
}

variable "subnets" {
  description = "List of IDs of subnets for the EC2 subnet group."
  type        = list(string)
}

variable "access_security_group" {
  description = "ID of a security group whose members can access the EC2 instance."
  type        = string
}

#variable "instance_count" {
#  description = "Number of EC2 instances required"
#  type        = string
#}

variable "instance_type" {
  description = "Instance type such as t2.micro"
  type        = string
}

#variable "keypair" {
#  type        = string
#  description = "Key pair used for RDPing into servers"
#}

variable "aws_region" {
  type        = string
  description = "Region for AWS Resources"
  default     = "eu-west-2"
}

variable "user_data" {
  description = "Powershell scripts used upon creating EC2 instances"
  type        = string
}

variable "encrytped" {
  type = bool 
  description = "Encryption for volumes"
}

variable "device_name" {
  type = string
  description = "Name of device in AWS"
}

variable "volume_type" {
  type = string
  description = "Volume type for volumes"
  default = "gp3"
}

variable "volume_size" {
  type = string
  description = "Size of volume"
}