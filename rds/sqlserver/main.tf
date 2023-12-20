##
# AWS RDS SQL Server
#
# See README.md for details on using this module.
##

provider "random" {
  version = "~> 3.0.0"
}

resource "aws_db_subnet_group" "subnet_group" {
  name = lookup(var.override_names, "subnet_group", "${var.name}-subnet-group")
  tags = merge({
    "Name" = "${var.name}-subnet-group"
  }, var.tags)
  subnet_ids = var.subnets
}

resource "aws_db_option_group" "option_group" {
  # We include the edition and the engine version in the name because changing either of those
  # forces a replacement. Deleting an option group takes a *very* long time as for some reason AWS
  # thinks its still in use for a long time after the RDS instance is gone. To limit the fallout of
  # changing the engine, changing the name means that at least Terraform can create a new option
  # group and proceed with the rest of its plan, even if it can't get rid of the old one yet.
  # To take advantage of this, use `terraform state rm` to "forget" the option group, and then
  # manually delete it in the AWS console later.
  name = lookup(var.override_names, "option_group", "${var.name}-option-group-sqlserver-${var.edition}-${replace(var.engine_version, ".", "-")}")
  tags = merge({
    "Name" = "${var.name}-option-group-sqlserver-${var.edition}-${var.engine_version}"
  }, var.tags)
  option_group_description = lookup(var.override_names, "option_group_description", "Option group for ${var.name} (Terraform)")

  engine_name          = "sqlserver-${var.edition}"
  major_engine_version = var.engine_version

  dynamic "option" {
    for_each = var.role_for_native_backups != null ? [1] : []
    content {
      option_name = "SQLSERVER_BACKUP_RESTORE"
      option_settings {
        name  = "IAM_ROLE_ARN"
        value = var.role_for_native_backups
      }
    }
  }
}

data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  name               = lookup(var.override_names, "enhanced_monitoring_role", "${var.name}-enhanced-monitoring")
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rds_assume_role.json
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_security_group" "security_group" {
  name        = lookup(var.override_names, "rds_security_group", "${var.name}-rds-sg")
  description = lookup(var.override_names, "rds_security_group_description", "Inbound access to ${var.name} SQL Server")
  tags = merge({
    "Name" = "${var.name}-rds-sg"
  }, var.tags)

  vpc_id = var.vpc_id

  ingress = [
    {
      description      = ""
      protocol         = "tcp"
      from_port        = 1433
      to_port          = 1433
      cidr_blocks      = []
      security_groups  = [var.access_security_group]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
  ]

  egress = [
    {
      description      = ""
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]
}

resource "random_password" "sql_server_password" {
  length      = 16
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "aws_db_instance" "rds_instance" {
  identifier = lookup(var.override_names, "rds_instance", "${var.name}-rds-instance")
  tags = merge({
    "Name" = "${var.name}-rds-instance"
  }, var.tags)

  engine                     = "sqlserver-${var.edition}"
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  multi_az                   = var.multi_az
  license_model              = "license-included"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  db_subnet_group_name       = aws_db_subnet_group.subnet_group.name
  option_group_name          = aws_db_option_group.option_group.name
  backup_retention_period    = 35
  username                   = "admin"
  password                   = random_password.sql_server_password.result
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.name}-final-snapshot"
  vpc_security_group_ids     = [aws_security_group.security_group.id]
  allocated_storage          = var.initial_storage_size
  max_allocated_storage      = var.maximum_storage_size
  storage_encrypted          = var.kms_key_id != null ? true : null
  kms_key_id                 = var.kms_key_id

  performance_insights_enabled          = var.production_monitoring
  performance_insights_kms_key_id       = var.production_monitoring ? var.kms_key_id : null
  performance_insights_retention_period = var.production_monitoring ? 731 : 0
  monitoring_interval                   = var.production_monitoring ? 60 : 0
  monitoring_role_arn                   = var.production_monitoring ? aws_iam_role.enhanced_monitoring.arn : null
  enabled_cloudwatch_logs_exports       = var.production_monitoring ? ["agent", "error"] : []

  # Prevent deletion. Note that these are hardcoded (which, in the case of the lifecycle option, is mandatory),
  # rather than in a variable, so if you want to delete this stack you will have to change this module. This is
  # an inconvenience, but less inconvenient than restoring an unintentionally-deleted database.

  # Prevent deletion by explicit action (AWS "protect from termination" option)
  deletion_protection = true
  lifecycle {
    # Prevent deletion by Terraform - either by `terraform destroy` or by changing an attribute that will cause a "needs replaced" plan
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret" "secret" {
  name = lookup(var.override_names, "secrets_manager_secret_name", "${var.name}-rds-credentials")
  tags = merge({
    "Name" = "${var.name}-rds-credentials"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "secret_data" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    "username" : aws_db_instance.rds_instance.username
    "password" : random_password.sql_server_password.result
    "engine" : "sqlserver"
    "host" : aws_db_instance.rds_instance.address
    "port" : aws_db_instance.rds_instance.port
    "dbInstanceIdentifier" : aws_db_instance.rds_instance.identifier
  })
}
