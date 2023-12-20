##
# For more details on the settings for RDS variables see the latest pages on Terraform:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
#
##

####
# Required
####
variable "name_prefix" {
  description = "The name used as the basis for all resources"
  type        = string
}

####
# Conditional
####

# Either `backup_tag_key` or `backup_selection_arns` must be specified (both can be specified)
variable "backup_tag_key" {
  description = "The key of the tag assigned to resources that will be backed up.  These backups use tags on resources to identify which resources to backup"
  type        = string
  default     = null
}

variable "backup_tag_value" {
  description = "The vale of the tag assigned to resources that will be backed up.  Suggested tags are standard, mission-critical etc..."
  type        = string
  default     = null
}

variable "backup_selection_arns" {
  description = "A list of ARNs of resources to backup"
  type        = list(string)
  default     = null
}

variable "enable_lock_main_vault" {
  description = "Whether to enable backup vault lock" # Once enabled, it will be impossible for _any user_ to remove backups before they have expired
  type        = bool
  default     = false
}

####
# Optional
####

# The maps should contain `rule_name`, `backup_schedule`, `lifecycle_delete_days_main_region`
# It can also optionally contain `lifecycle_delete_days_second_region`
# eg:
#
# [
#    {
#       rule_name                          = "Daily backup"
#       backup_schedule                    = "cron(0 4 ? * * *)"
#       lifecycle_delete_days              = "31"
#       lifecycle_delete_days_second_vault = "31" # optional
#    }
# ]
variable "rules" {
  description = "A list of maps containing the rule_name, backup_schedule and lifecycle_delete_days for the rules"
  type        = list(map(string))
  default     = []
}

variable "second_vault_arn" {
  description = "The ARN of a second DR vault where all backups should be copied"
  type        = string
  default     = null
}

####
# Optional name overrides
####
variable "backup_vault_name" {
  description = "The name for the backup vault that will be used"
  type        = string
  default     = null
}

variable "backup_plan_name" {
  description = "The name for the backup plan that will be used"
  type        = string
  default     = null
}

variable "backup_rule_name" {
  description = "The name for the backup rules that will be used"
  type        = string
  default     = null
}

variable "backup_selection_name" {
  description = "The name for the backup selection that will be used and where the scope of which resources will be backed up is defined"
  type        = string
  default     = null
}

variable "iam_backup_role_name" {
  description = "The name of the IAM role that will be used by AWS Backup to perform the backups"
  type        = string
  default     = null
}

variable "notification_email_addresses" {
  description = "List of email addresses that will receive notifications for backup vault events"
  type        = list(string)
  default     = []
}