resource "aws_cloudwatch_metric_alarm" "sql_server_is_reporting_metric_data" {
  count = var.sns_urgent_priority == null ? 0 : 1

  alarm_name        = "${var.name}-is-reporting-metric-data"
  alarm_description = "Alarms if the database instance is not healthy enough to report metric data"

  actions_enabled           = true
  alarm_actions             = [var.sns_urgent_priority]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"
  dimensions = {
    "DBInstanceIdentifier" = aws_db_instance.rds_instance.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = 0

  datapoints_to_alarm = 2
  evaluation_periods  = 2
  extended_statistic  = "p10"
  period              = 300
  treat_missing_data  = "breaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "sql_server_free_space_critical" {
  count = var.sns_urgent_priority == null ? 0 : 1

  alarm_name        = "${var.name}-rds-instance-critical-disk-space"
  alarm_description = "Alarms if free disk space falls below 20% of allocated storage"

  actions_enabled           = true
  alarm_actions             = [var.sns_urgent_priority]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"
  dimensions = {
    "DBInstanceIdentifier" = aws_db_instance.rds_instance.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = (var.initial_storage_size - (var.initial_storage_size * 0.8)) * 1000000000 # 20% of initial storage size

  datapoints_to_alarm = 2
  evaluation_periods  = 2
  extended_statistic  = "p10"
  period              = 300
  treat_missing_data  = "missing"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "prolonged-cpu-usage" {
  count = var.sns_high_priority == null ? 0 : 1

  alarm_name        = "${var.name}-rds-instance-prolonged-cpu-usage"
  alarm_description = "Alarms if CPU utilization exceeds 90% for more than 2 hours in a day. Indicates a possible need to re-size the instance."

  actions_enabled           = true
  alarm_actions             = [var.sns_high_priority]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  dimensions = {
    "DBInstanceIdentifier" = aws_db_instance.rds_instance.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 90

  datapoints_to_alarm = 24  # Number of 5-minute periods in 2 hours
  evaluation_periods  = 288 # Number of 5-minute periods in 24 hours
  statistic           = "Average"
  period              = 300

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "prolonged-low-freeable-memory" {
  count = var.sns_high_priority == null ? 0 : 1

  alarm_name        = "${var.name}-rds-instance-prolonged-low-freeable-memory"
  alarm_description = "Alarms if freeable memory falls below 1GiB for more than 2 hours in a day. Indicates a possible need to re-size the instance."

  actions_enabled           = true
  alarm_actions             = [var.sns_high_priority]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/RDS"
  metric_name = "FreeableMemory"
  dimensions = {
    "DBInstanceIdentifier" = aws_db_instance.rds_instance.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = 1073741824 # 1GB in bytes

  datapoints_to_alarm = 24  # Number of 5-minute periods in 2 hours
  evaluation_periods  = 288 # Number of 5-minute periods in 24 hours
  statistic           = "Average"
  period              = 300

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high-read-latency" {
  count = var.sns_high_priority == null ? 0 : 1

  alarm_name        = "${var.name}-rds-instance-high-read-latency"
  alarm_description = "Alarm if more than 1% of disk reads in an hour takes longer than ${var.read_latency_threshold} seconds."

  actions_enabled           = true
  alarm_actions             = [var.sns_high_priority]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/RDS"
  metric_name = "ReadLatency"
  dimensions = {
    "DBInstanceIdentifier" = aws_db_instance.rds_instance.identifier
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.read_latency_threshold

  datapoints_to_alarm = 1
  evaluation_periods  = 1
  extended_statistic  = "p99"
  period              = 3600

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high-write-latency" {
  count = var.sns_high_priority == null ? 0 : 1

  alarm_name        = "${var.name}-rds-instance-high-write-latency"
  alarm_description = "Alarm if more than 1% of disk writes in an hour takes longer than ${var.write_latency_threshold} seconds."

  actions_enabled           = true
  alarm_actions             = [var.sns_high_priority]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/RDS"
  metric_name = "WriteLatency"
  dimensions = {
    "DBInstanceIdentifier" = aws_db_instance.rds_instance.identifier
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.write_latency_threshold

  datapoints_to_alarm = 1
  evaluation_periods  = 1
  extended_statistic  = "p99"
  period              = 3600

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high-disk-queue-depth" {
  count = var.sns_high_priority == null ? 0 : 1

  alarm_name        = "${var.name}-rds-instance-high-disk-queue-depth"
  alarm_description = "Alarm if the disk queue depth is longer than ${var.disk_queue_depth_threshold} operations for more than 1% of an hour."

  actions_enabled           = true
  alarm_actions             = [var.sns_high_priority]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/RDS"
  metric_name = "DiskQueueDepth"
  dimensions = {
    "DBInstanceIdentifier" = aws_db_instance.rds_instance.identifier
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.disk_queue_depth_threshold

  datapoints_to_alarm = 1
  evaluation_periods  = 1
  extended_statistic  = "p99"
  period              = 3600

  tags = var.tags
}

resource "aws_db_event_subscription" "urgent" {
  count = var.sns_urgent_priority == null ? 0 : 1

  name      = "${var.name}-rds-events-urgent"
  sns_topic = var.sns_high_priority

  source_type = "db-instance"
  source_ids  = [aws_db_instance.rds_instance.id]

  event_categories = [
    "deletion",
    "failure",
  ]
}

resource "aws_db_event_subscription" "high" {
  count = var.sns_high_priority == null ? 0 : 1

  name      = "${var.name}-rds-events-high"
  sns_topic = var.sns_high_priority

  source_type = "db-instance"
  source_ids  = [aws_db_instance.rds_instance.id]

  event_categories = [
    "availability",
    "failover",
    "notification",
    "read replica",
    "recovery",
  ]
}

resource "aws_db_event_subscription" "low" {
  count = var.sns_low_priority == null ? 0 : 1

  name      = "${var.name}-rds-events-low"
  sns_topic = var.sns_high_priority

  source_type = "db-instance"
  source_ids  = [aws_db_instance.rds_instance.id]

  event_categories = [
    "low storage",
    "maintenance",
    "restoration",
  ]
}
