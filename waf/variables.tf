# For tags and naming

variable "name" {
  description = "Name (kebab-case-format recommended) that will be used to prefix resource names."
  type        = string
}

variable "tags" {
  description = "Map of tags to be applied to all supported resources"
  type        = map(string)
}

# For Web ACL configuration

variable "web_acl_scope" {
  description = "Specifies whether this is for an AWS CloudFront distribution or for a regional application. Valid values are CLOUDFRONT or REGIONAL. To work with CloudFront, you must also specify the region us-east-1 (N. Virginia) on the AWS provider."
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.web_acl_scope)
    error_message = "Allowed values for backend_servers are \"REGIONAL\" or \"CLOUDFRONT\"."
  }
}

# For functionality

variable "backend_server_type" {
  description = "Type of backend servers, so know which rules to include (linux|windows|n/a)"
  type        = string
  default     = "n/a"

  validation {
    condition     = contains(["linux", "windows", "n/a"], var.backend_server_type)
    error_message = "Allowed values for backend_servers are \"linux\", \"windows\", or \"n/a\"."
  }
}

variable "sql_rule_enabled" {
  description = "Whether to enable the AWS managed rule group for SQL exploits."
  type        = bool
  default     = true
}

variable "allowlist_addresses" {
  description = "List of CIDR blocks to include in the allowlist, e.g. ['1.2.3.4/32']"
  type        = list(string)
  default     = []
}

variable "denylist_addresses" {
  description = "List of CIDR blocks to include in the denylist, e.g. ['1.2.3.4/32']"
  type        = list(string)
  default     = []
}

variable "denylist_geos" {
  description = "List of ISO 3166 alpha-2 country codes to deny, e.g. ['GB','AQ']"
  type        = list(string)
  default     = []
}

variable "rate_limit" {
  description = "Max number of requests in 5 mins from an IP address, before rate-limiting"
  type        = number
  default     = 2000 //AWS Whitepaper recommends starting with 2000
}

# For monitoring
#
# These alerting thresholds are set low initially, but will likely need to be adjusted

variable "rate_limit_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for rate-limit Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "block_urls_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for block-urls Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "common_rules_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for common-rules Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "known_bad_inputs_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for known-bad-inputs Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "sql_injection_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for sql-injection Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "ip_reputation_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for ip-reputation Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "unix_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for unix Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "linux_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for linux Cloudwatch alarm"
  type        = number
  default     = 10
}

variable "windows_cloudwatch_alarm_threshold" {
  description = "Alerting threshold for windows Cloudwatch alarm"
  type        = number
  default     = 10
}
