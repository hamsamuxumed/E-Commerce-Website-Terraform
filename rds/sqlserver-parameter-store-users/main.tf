##
# AWS RDS SQL Server Users
# We want a persistent set of users that we can hold details for in parameter
# store.  This means in a recovery scenario those users can be re-deployed
# using information persisted in parameter store and so they keep the same 
# usernames, passwords etc...
#
# Note that this starts to put sensitive data into the state which is held 
# remotely in non-public s3 buckets, which should be fine, but there should be
# an awareness
#
# see https://developer.hashicorp.com/terraform/language/state/sensitive-data
# for more details
#
##
#
# Create a secret entry for the given user
resource "aws_ssm_parameter" "secret" {
  name        = var.ssm_password_path
  description = "Database user password for ${var.user}"
  type        = "SecureString"
  value       = var.random_password
  # This is important.  Lifecycle changes are being set to ignore any changes
  # This means that once the ssm_parameter is changed anything within it that
  # changes via the console Terraform will ignore.  You can still delete the 
  # parameter and create new ones, but anything within the resource, in this
  # case ssm_parameter will be ignored and not picked up by Terraform.
  # In this case, this is the desired behaviour, but should be used with 
  # caution.
  lifecycle {
    ignore_changes = all
  }

  tags = var.tags
}

# Some useful posts in the research of developing this
#https://nsirap.com/posts/065-terraform-for-each-from-json-file/
#https://discuss.hashicorp.com/t/auto-generated-integers-or-passwords-inside-module-that-is-using-for-each/13893
