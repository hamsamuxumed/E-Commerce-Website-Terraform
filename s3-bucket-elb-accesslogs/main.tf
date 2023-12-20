##
# S3 bucket that can be used for ELB access-logs storage
#
# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
##

data "aws_region" "current" {}

locals {
  bucket_policy = templatefile("${path.module}/policies/bucket-policy-template.json", local.template_vars)
  log_delivery_acc_id = {
    "us-east-1"      = "127311923021"
    "us-east-2"      = "033677994240"
    "us-west-1"      = "027434742980"
    "us-west-2"      = "797873946194"
    "af-south-1"     = "098369216593"
    "ca-central-1"   = "985666609251"
    "eu-central-1"   = "054676820928"
    "eu-west-1"      = "156460612806"
    "eu-west-2"      = "652711504416"
    "eu-south-1"     = "635631232127"
    "eu-west-3"      = "009996457667"
    "eu-north-1"     = "897822967062"
    "ap-east-1"      = "754344448648"
    "ap-northeast-1" = "582318560864"
    "ap-northeast-2" = "600734575887"
    "ap-northeast-3" = "383597477331"
    "ap-southeast-1" = "114774131450"
    "ap-southeast-2" = "783225319266"
    "ap-south-1"     = "718504428378"
    "me-south-1"     = "076674570225"
    "sa-east-1"      = "507241528517"
    "us-gov-west-1"  = "048591011584"
    "us-gov-east-1"  = "190560391635"
    "cn-north-1"     = "638102146993"
    "cn-northwest-1" = "037604701340"
  }
  template_vars = {
    bucket_name             = var.bucket_name
    elb_delivery_account_id = local.log_delivery_acc_id[data.aws_region.current.name]
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
