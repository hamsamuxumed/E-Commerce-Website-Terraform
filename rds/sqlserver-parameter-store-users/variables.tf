// Naming and tagging

variable "user" {
  description = "The name of the sql server user that will be created"
  type        = string
}

variable "random_password" {
  description = "The password allocated to the user initially"
  type        = string
}

variable "environment" {
  description = "The environment in which the parameter is being deployed"
  type        = string
}

variable "ssm_password_path" {
  description = "The parameter store path to the password for the database user"
  type        = string
}

variable "tags" {
  description = "Map of tags to be applied to all supported resources"
  type        = map(string)
}

// variable "users" {
//  description = "Map of users who need access to the database(s)"
//  type        = map(string)
// }

