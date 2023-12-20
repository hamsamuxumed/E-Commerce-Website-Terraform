# backup module

## Overview

This Terraform module provides a basic AWS Backup configuration. It configures a single AWS Backups vault and an associated plan to back up any supported resources which match the specified tag, or are specified directly by their ARNs. The plan can contain multiple backup rules with different schedules and retentions. The module optionally supports copying the backups to a separate DR vault (not created by the module) and also supports locking the vault to protect the backups against accidental or malicious deletion. The module also optionally supports setting up email notifications of interesting events, such as restores or failed backups.

### AWS Components

- **AWS Backup Vault** - The backup vault is the container that organises and stores the backups. This module uses the default aws/backups KMS key for encryption.
- **AWS Backup Vault Lock** - If this is enabled, then the recovery points (backups) cannot be deleted by anyone before the configured time period has elapsed.
- **AWS Backup Plan** - This configures how and when the AWS resources are backed up, and how long backups are retained for.
- **AWS Backup Resource Selection** - This selects which resources will be backed up by the plan.
- **IAM Role** - The role used by AWS Backup to backup the selected resources. This uses a managed policy which allows AWS Backups to create backups of all supported resources.
- **SNS Topic and Policy** - Receives interesting events from AWS Backup
- **SNS Subscriptions** - Optionally adds an email subscriber to receive notifications of restore or failed backup events

## How To Use

### Resource Selection

Resources to be backed up can be selected using tags (recommended) or their specific ARNs. one of these options must be used, or both can be if desired.

To backup resources tagged with `backup: daily`

```terraform
  backup_tag_key                    = "backup"
  backup_tag_value                  = "daily"
```

To backup specific resources by ARN:

```terraform
  backup_selection_arns             = ["arn:aws:rds:eu-west-2:987654321000:cluster:dave-rds-cluster"]
```

### Backup rules (schedule and retention)

You must specify one (or more) backup rules which are used by the backup plan. The rules are specified as a list of maps. Each map must contain the keys `rule_name`, `backup_schedule` and `lifecycle_delete_days`. Optionally `lifecycle_delete_days_second_vault` can be supplied if a second DR vault is in use (see section below).

To add a daily and a monthly backup rule:

```terraform
rules = [
    {
        rule_name = "daily"
        backup_schedule         = "cron(0 1 * * ? *)"
        lifecycle_delete_days   = 31
    }
    {
        rule_name = "monthly"
        backup_schedule         = "cron(0 4 1 * ? *)"
        lifecycle_delete_days   = 365
    }
  ]
```

### Disaster Recovery

You can optionally supply the ARN of a second AWS backups vault in a different region or AWS account, and any backups created by the plan will then be copied to this vault. The DR vault is not created by this module, it must be created separately.

To send the backups to another AWS account, additional configuration steps must be carried out. For more details, see the AWS documentation here: [Creating backup copies across AWS accounts](https://docs.aws.amazon.com/aws-backup/latest/devguide/create-cross-account-backup.html).

For each rule in the rules section you can optionally supply a `lifecycle_delete_days_second_vault` key.

To configure:

```terraform
  second_vault_arn = "arn:aws:backup:eu-central-1:419367205549:backup-vault:daves-excellent-application-dr-vault"
  rules = [
    {
        rule_name = "daily"
        backup_schedule                    = "cron(0 1 * * ? *)"
        lifecycle_delete_days              = 31
        lifecycle_delete_days_second_vault = 180 # optional, defaults to the same as lifecycle_delete_days
    }
  ]
```

Also see the Examples section below for a more detailed example.

### Backup Vault Lock

It is a good idea to enable this lock, but please first ensure that your retention polcy is set up appropriately.
Once a vault has been locked and the cooling off period has passed, it is impossible for anyone to delete the backups until the specified period has elapsed.

To lock a vault:

```terraform
  enable_lock_main_vault            = true
```

### SNS Email Notifications

If email addresses are provided, an SNS subscription will be created for each email address. When SNS subscription is created, a confirmation email will be sent out and much be confirmed by clicking the link. The email addresses will then recieve notification of the following events (for the backup vault created by this module):

- Backup job failure
- Copy job failure
- Restore job start

To supply a list of email addresses which should recieve notifications:

```terraform
  notification_email_addresses = [ "operations@black-mesa.com", "elon@tesla.com" ]
```

### Examples

The simple configuration below will backup all supported resources which are tagged with `backup: daily`. Backups will be made daily at 04:00 and will be kept for 31 days.

```terraform
module "backup_vault" {
  source = "./modules/backup"

  name_prefix                       = "daves-excellent-application"

  backup_tag_key                    = "backup"
  backup_tag_value                  = "daily"

  rules = [
    {
        rule_name = "daily"
        backup_schedule             = "cron(0 4 * * ? *)"
        lifecycle_delete_days       = 31
    }
  ]
}
```

The configuration below will backup all supported resources which are tagged with `backup: weekly`, and the additional RDS cluster specified.  Backups will be made weekly on Mondays at 06:00, and will be retained for 180 days. The backup vault will be locked so that backups cannot be deleted.

```terraform
module "backup_vault" {
  source = "./modules/backup"

  name_prefix                       = "daves-excellent-application"
  enable_lock_main_vault            = true

  backup_tag_key                    = "backup"
  backup_tag_value                  = "daily"
  backup_selection_arns             = ["arn:aws:rds:eu-west-2:987654321000:cluster:dave-rds-cluster"]

  rules = [
    {
        rule_name = "weekly"
        backup_schedule             = "cron(0 6 ? * MON *)"
        lifecycle_delete_days       = 180
    }
  ]
}
```

The configuration below shows how to configure all backups to be copied to an additional DR vault in a different region. Please note that any **vault lock** configurations created through the module are not applied to the DR vault.

```terraform
# Default provider which will be used by all resources unless otherwise specified
provider "aws" {
  region = "eu-west-2"
}

# DR provider in alternate region
provider "aws" {
  region = "eu-central-1"
  alias  = "dr"
}

# Create additional vault by specifying aws.dr provider
resource "aws_backup_vault" "dr_vault" {
  provider = aws.dr
  name     = "${local.application}-dr-vault"
}

module "backup_vault" {
  source = "./modules/backup"

  name_prefix                       = local.application
  second_vault_arn                  = aws_backup_vault.dr_vault.arn # Reference the ARN of DR the vault created above

  rules = [
    {
        rule_name = "daily"
        backup_schedule            = "cron(0 4 * * ? *)"
        lifecycle_delete_days      = 31
    }
  ]

  backup_tag_key                    = "backup"
  backup_tag_value                  = "daily"
}
```

The configuration below will backup all supported resources which are tagged with `backup: weekly`. Backups will be made weekly on Mondays at 06:00, and will be retained for 180 days. The backup vault will be locked so that backups cannot be deleted, and email notifications will be configured for any restore or backup failure events.

```terraform
module "backup_vault" {
  source = "./modules/backup"

  name_prefix                       = "daves-excellent-application"
  enable_lock_main_vault            = true

  backup_tag_key                    = "backup"
  backup_tag_value                  = "daily"
  backup_selection_arns             = ["arn:aws:rds:eu-west-2:987654321000:cluster:dave-rds-cluster"]

  rules = [
    {
        rule_name = "weekly"
        backup_schedule             = "cron(0 6 ? * MON *)"
        lifecycle_delete_days       = 180
    }
  ]

  notification_email_addresses = ["ops@acme.com"]
}
```
