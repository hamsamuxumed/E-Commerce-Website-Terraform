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

variable "instance_type" {
  description = "EC2 instance type, e.g. t3.micro"
  type        = string
}

// Networking

variable "vpc_id" {
  description = "ID of the VPC to contain the resources."
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet to deploy the bastion into"
  type        = string
}

variable "security_group" {
  description = "The security group to attach to the bastion instance"
  type        = string
}