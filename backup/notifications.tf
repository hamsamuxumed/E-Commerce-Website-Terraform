################################################################################
# Notifications & SNS
################################################################################
# To monitor backup events, AWS Backup is configured to send certain events to
# an SNS topic. If email addresses are provided to the module then SNS
# subscriptions will be created to deliver notifications of interesting events.

resource "aws_backup_vault_notifications" "backup_notifications" {
  backup_vault_name   = aws_backup_vault.main.name
  sns_topic_arn       = aws_sns_topic.backup_notifications_topic.arn
  backup_vault_events = [
    "BACKUP_JOB_COMPLETED",
    "COPY_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED", # These notifications will be filtered out (see comment in subscription resource)
    "RECOVERY_POINT_MODIFIED" # These notifications will be filtered out (see comment in subscription resource)
  ]
}

resource "aws_sns_topic" "backup_notifications_topic" {
  name = var.backup_vault_name != null ? "${var.backup_vault_name}-notifications" : "${var.name_prefix}-backup-notifications"
}

data "aws_iam_policy_document" "backup_notifications_policy_doc" {
  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.backup_notifications_topic.arn,
    ]

    sid = "1"
  }
}

resource "aws_sns_topic_policy" "backup_notifications_policy" {
  arn    = aws_sns_topic.backup_notifications_topic.arn
  policy = data.aws_iam_policy_document.backup_notifications_policy_doc.json
}

# These email addresses must be confirmed (by clcking the link in the confirmaton email) after
# they have been created.
#
# If the subscription is not confirmed, then it cannot be removed by Terraform (or through the
# API at all). In this case destroying the Terraform resource will remove the aws_sns_topic_subscription
# from Terraform's state but will not remove the subscription from AWS.
resource "aws_sns_topic_subscription" "backup_notification_subscription" {
  for_each = toset(var.notification_email_addresses)

  topic_arn = aws_sns_topic.backup_notifications_topic.arn
  protocol  = "email"
  endpoint  = each.value

  # The only way to get notifications of backup failures is to subscribe to BACKUP_JOB_COMPLETED events
  # and filter out any with State = COMPLETED
  # However, SNS filters don't support applying OR logic across different message attributes, so we can't
  # be specific about which State = COMPLETED events we want to filter - this means some additional events
  # will be filtered, such as RESTORE_JOB_COMPLETED and RECOVERY_POINT_MODIFIED.
  # If required it should be possible to work around this by creating multiple SNS subscriptions. More info here:
  # https://docs.aws.amazon.com/sns/latest/dg/and-or-logic.html
  filter_policy = <<EOF
  {
    "State": [
      {
        "anything-but": "COMPLETED"
      }
    ]
  }
EOF
}
