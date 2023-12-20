##
# EFS volume
#
# See README.md for details on using this module.
##

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_kms_key" "EFS" {
  key_id = "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/elasticfilesystem"
}
data "aws_subnet" "selected" {
  id = var.subnets[0]
}

resource "aws_security_group" "EFSVolume" {
  name        = var.override_security_group_name != null ? var.override_security_group_name : "${var.name}-efs"
  description = var.override_security_group_description != null ? var.override_security_group_description : "Grants access to EFS volume ${aws_efs_file_system.EFSFileSystem.id}"
  tags = merge({
    "Name" = "${var.name}-efs"
  }, var.tags)

  vpc_id = data.aws_subnet.selected.vpc_id
  ingress {
    security_groups = [
      var.access_security_group
    ]
    protocol  = "tcp"
    from_port = 2049
    to_port   = 2049
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_mount_target" "mount_target" {
  for_each = toset(var.subnets)

  file_system_id  = aws_efs_file_system.EFSFileSystem.id
  subnet_id       = each.key
  security_groups = [aws_security_group.EFSVolume.id]
}

resource "aws_efs_file_system" "EFSFileSystem" {
  tags = merge({
    "Name" = "${var.name}-efs"
  }, var.tags)

  performance_mode = "generalPurpose"
  encrypted        = true
  kms_key_id       = data.aws_kms_key.EFS.arn
  throughput_mode  = "bursting"
}
