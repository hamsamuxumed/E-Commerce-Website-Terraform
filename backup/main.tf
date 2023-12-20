######################################################################
# Provider Setup
######################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
  }
}

# Lets keep IAM policy statements out of the main.tf, this keeps json
# separate and is neater
locals {
  iam_backup_trust_relationship = templatefile("${path.module}/policies/iam_backup_trust_relationship.json", local.template_vars)
  template_vars                 = {}
}

################################################################################
# Backup vault setup
################################################################################
# Note: without specifying the kms_key_arn it will use the default AWS KMS key
resource "aws_backup_vault" "main" {
  name = var.backup_vault_name != null ? var.backup_vault_name : "${var.name_prefix}-backup-vault"
}

################################################################################
# Backup plan
################################################################################
# This is the template to define the schedule to use for backups, the copy to a
# second region and how long to retain the backups for.
resource "aws_backup_plan" "main" {
  name = var.backup_plan_name != null ? var.backup_plan_name : "${var.name_prefix}-backup-plan"

  dynamic rule {
    for_each = var.rules
    content {
      rule_name         = rule.value["rule_name"]
      schedule          = rule.value["backup_schedule"]
      target_vault_name = aws_backup_vault.main.name
      lifecycle {
        delete_after = rule.value["lifecycle_delete_days"]
      }

    # If the ARN is provided for a DR vault, backups will be copied there
      dynamic "copy_action" {
        for_each = var.second_vault_arn != null ? ["true"] : []
        content {
          destination_vault_arn = var.second_vault_arn
          lifecycle {
            # Use lifecycle_delete_days_second_vault if provided, otherwise default to lifecycle_delete_days
            delete_after = lookup(rule.value, "lifecycle_delete_days_second_vault", rule.value["lifecycle_delete_days"])
          }
        }
      }
    }
  }
}

################################################################################
# Resource selection
################################################################################
# It is best to backup based on tags.  This is more stable, because if the
# underlying resource is replaced it's resource id will change and the backup
# will no longer work.  As long as the tags remain consistent then backups will
# continue.
# However it is also possible to specify resources through a list of ARNs.
resource "aws_backup_selection" "main" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = var.backup_selection_name != null ? var.backup_selection_name : "${var.name_prefix}-backup-selection"
  plan_id      = aws_backup_plan.main.id

  # selection_tag is only configured if var.backup_tag_key has been provided
  dynamic "selection_tag" {
    for_each = var.backup_tag_key != null ? ["true"] : []
    content {
      type  = "STRINGEQUALS"
      key   = var.backup_tag_key
      value = var.backup_tag_value
    }
  }

  # A list of resource ARNs can be provided instead of (or in addition to) selection_tag
  resources = var.backup_selection_arns
}

################################################################################
# IAM Setup
################################################################################
# This section creates an IAM role which is used by AWS Backup to create the
# backups of selected resources. This role is not used for restores.
resource "aws_iam_role" "backup_role" {
  name               = var.iam_backup_role_name != null ? var.iam_backup_role_name : "${var.name_prefix}-backup-role"
  assume_role_policy = local.iam_backup_trust_relationship
}

resource "aws_iam_role_policy_attachment" "AWSManagedPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

################################################################################
# Backup Vault Lock
################################################################################
# If var.enable_lock_main_vault is true, then AWS Backup Vault Lock will be configured.
# This prevents _anyone_ (even the root user) from deleting the backups before they expire,
# so you must ensure that the retention settings are correct before enabling it.
resource "aws_backup_vault_lock_configuration" "vault_lock" {
  count               = var.enable_lock_main_vault == true ? 1 : 0
  backup_vault_name   = aws_backup_vault.main.name
  changeable_for_days = 3 # Cooling off period, during which you can still make changes to the lock
  min_retention_days  = min([for rule in var.rules : rule["lifecycle_delete_days"]])
}
