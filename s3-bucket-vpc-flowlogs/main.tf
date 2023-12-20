##
# S3 bucket that can be used for ELB access-logs storage
#
# See https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3.html#flow-logs-s3-permissions
##

locals {
  bucket_policy = templatefile("${path.module}/policies/bucket-policy-template.json", local.template_vars)
  template_vars = {
    bucket_name = var.bucket_name
  }
}

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  acl    = "private"
  policy = local.bucket_policy

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id                                     = "expiration"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 7

    expiration {
      days = var.object_expiration_days
    }
  }

  tags = merge({
    "Name" = var.bucket_name
  }, var.tags)
}
