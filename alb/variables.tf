// Control of placement

variable "vpc_id" {
  type = string
}

// Control of behaviour

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
}

variable "access_logs_s3_bucket_name" {
  description = "S3 Bucket name in which to write access logs, or access-logs are disabled if blank"
}

variable "acm_certificate_arn" {
  description = "S3 Bucket name in which to write access logs, or access-logs are disabled if blank"
}

variable "inbound_cidrs" {
  description = "List of CIDRs of addresses permitted to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "Security group ids to attach to ALB, as well as the default"
  type        = list(string)
  default     = []
}

variable "web_acl_arn" {
  description = "ACL WAFv2 arn (also see toggle_web_acl for whether this is enabled)"
  type        = string
  default     = ""
}

variable "web_acl_enabled" {
  description = "Whether to include the web ACL"
  type        = bool
  default     = true
}

variable "blue_green_tg_enabled" {
  description = "True to create a second target group for use in ECS blue/green deployments"
  type        = bool
  default     = false
}

variable "target_instances_port" {
  description = "The TCP port to use when forwarding requests to the EC2 instances, see target_instances_protocol"
  type        = number
  default     = 80
}

variable "target_instances_protocol" {
  description = "The protocol (HTTP or HTTPS) to use when forwarding requests to the EC2 instances, see target_instances_port"
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Set the load balancer target type - either \"instance\" (for EC2 instances) or \"ip\" (for other targets such as ECS containers)"
  type        = string
  default     = "instance"
}

variable "health_check_enabled" {
  description = "ALB target group's health check: whether it is enabled"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "ALB target group's health check: path to check"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "ALB target group's health check: the port to use (default's to 'traffic-port')"
  type        = string
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "ALB target group's health check: protocol to use"
  type        = string
  default     = "HTTP"
}

variable "health_check_matcher" {
  description = "ALB target group's health check: response codes to accept as healthy"
  type        = string
  default     = "200-299"
}

variable "health_check_healthy_threshold" {
  description = "ALB target group's health check: number of consecutive successes to be considered healthy"
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "ALB target group's health check: number of consecutive failures to be considered unhealthy"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "ALB target group's health check: time between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "ALB target group's health check: whether it is enabled"
  type        = number
  default     = 5
}


// For tags and naming

variable "name" {
  description = "Name (kebab-case-format recommended) that will be used to prefix resource names."
  type        = string
}

variable "tags" {
  description = "Map of tags to be applied to all supported resources"
  type        = map(string)
}


// Notifications

variable "sns_urgent" {
  description = "ARN of an SNS topic to receive urgent notifications"
}

variable "sns_normal" {
  description = "ARN of an SNS topic to receive normal notifications"
}


// Monitoring

variable "slow_request_threshold" {
  description = "Threshold in seconds for a slow request. 95% of requests in a day should be faster than this."
  type        = number
  default     = null
}

variable "very_slow_request_threshold" {
  description = "Threshold in seconds for a slow request. 99% of requests in a day should be faster than this."
  type        = number
  default     = null
}


// Special configuration

variable "override_alb_name" {
  description = "Explicit name for the Application Load Balancer, overriding the module's default name"
  type        = string
  default     = null
}

variable "override_target_group_name" {
  description = "Explicit name for the target group, overriding the module's default name"
  type        = string
  default     = null
}

variable "override_secondary_target_group_name" {
  description = "Explicit name for the secondary target group, overriding the module's default name"
  type        = string
  default     = null
}

variable "override_security_group_name" {
  description = "Explicit name for the security group, overriding the module's default name"
  type        = string
  default     = null
}

variable "override_security_group_description" {
  description = "Explicit description for the security group, overriding the module's default name"
  type        = string
  default     = null
}
