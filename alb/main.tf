locals {
  # Target groups in this module have some moderately complex rules for forumulating their names,
  # which looks hideous when expressed in Terraform. So we use local declarations to break it down
  # into something more readable.

  # Each array has three elements - the first two elements are for when blue/green deployments are in
  # use (so count.index can be used to index the array), the third for when a single TG is required.

  # The names to use if there's no overrides
  systematic_tg_names = [
    "${var.name}-tg1",
    "${var.name}-tg2",
    "${var.name}-tg",
  ]

  # The names to use if there are overrides - if no override, elements will appear as null
  override_tg_names = [
    var.override_target_group_name,
    var.override_secondary_target_group_name,
    var.override_target_group_name,
  ]

  # The names to *actually* use
  tg_names = [
    local.override_tg_names[0] != null ? local.override_tg_names[0] : local.systematic_tg_names[0],
    local.override_tg_names[1] != null ? local.override_tg_names[1] : local.systematic_tg_names[1],
    local.override_tg_names[2] != null ? local.override_tg_names[2] : local.systematic_tg_names[2],
  ]
}

resource "aws_lb" "main" {
  name               = var.override_alb_name != null ? var.override_alb_name : "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.public_subnets.ids
  security_groups = concat(
    [aws_security_group.alb_sg.id],
  var.additional_security_group_ids)
  idle_timeout               = 180
  enable_deletion_protection = var.deletion_protection

  access_logs {
    bucket  = var.access_logs_s3_bucket_name
    prefix  = "${var.name}-alb"
    enabled = var.access_logs_s3_bucket_name == "" ? false : true
  }

  tags = merge({
    "Name" = var.name
  }, var.tags)

  depends_on = [aws_security_group.alb_sg]
}

resource "aws_wafv2_web_acl_association" "web_acl" {
  # Unfortunately can't use `count = var.web_acl_arn == "" ...` because of wiring modules
  # together. `terraform plan` needs to know whether this will be enabled at design-time,
  # whereas web_acl_arn would be the output from another module so not known until runtime.
  count        = var.web_acl_enabled ? 1 : 0
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.web_acl_arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }

  lifecycle {
    ignore_changes = [default_action.0.target_group_arn] // In blue/green deployments, tg1 and tg2 swap on every deploy, so ignore that field changing
  }
}

resource "aws_lb_target_group" "tg" {
  count       = var.blue_green_tg_enabled ? 2 : 1
  name        = var.blue_green_tg_enabled ? local.tg_names[count.index] : local.tg_names[2]
  port        = var.target_instances_port
  protocol    = var.target_instances_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    enabled             = var.health_check_enabled
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    matcher             = var.health_check_matcher
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge({
    "Name" = var.blue_green_tg_enabled ? local.systematic_tg_names[count.index] : local.systematic_tg_names[2],
  }, var.tags)
}

resource "aws_security_group" "alb_sg" {
  name        = var.override_security_group_name != null ? var.override_security_group_name : "${var.name}-sg"
  description = var.override_security_group_description != null ? var.override_security_group_description : "Controls access to the ALB"
  vpc_id      = var.vpc_id

  tags = merge({
    "Name" = "${var.name}-sg"
  }, var.tags)
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.inbound_cidrs
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.inbound_cidrs
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_cloudwatch_metric_alarm" "healthy_hosts_low" {
  count = var.sns_urgent == null ? 0 : (var.blue_green_tg_enabled ? 2 : 1)

  alarm_name        = "${aws_lb_target_group.tg[count.index].name}-healthy-hosts-low"
  alarm_description = "Alarm if ${aws_lb_target_group.tg[count.index].name} is active but there are less than 2 healthy hosts"

  actions_enabled           = true
  alarm_actions             = [var.sns_urgent]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"
  dimensions = {
    "LoadBalancer" = aws_lb.main.arn_suffix
    "TargetGroup"  = aws_lb_target_group.tg[count.index].arn_suffix
  }
  comparison_operator = "LessThanThreshold"
  threshold           = 2

  datapoints_to_alarm = 4
  evaluation_periods  = 10
  extended_statistic  = "p10"
  period              = 60
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "slow_requests" {
  count = var.slow_request_threshold == null ? 0 : (var.blue_green_tg_enabled ? 2 : 1)

  alarm_name        = "${aws_lb_target_group.tg[count.index].name}-slow-requests"
  alarm_description = "Alarm if 5% of requests to ${aws_lb_target_group.tg[count.index].name} take longer than ${var.slow_request_threshold} seconds"

  actions_enabled           = true
  alarm_actions             = [var.sns_normal]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  dimensions = {
    "LoadBalancer" = aws_lb.main.arn_suffix
    "TargetGroup"  = aws_lb_target_group.tg[count.index].arn_suffix
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.slow_request_threshold

  datapoints_to_alarm = 1
  evaluation_periods  = 1
  extended_statistic  = "p95"
  period              = 86400
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "very_slow_requests" {
  count = var.very_slow_request_threshold == null ? 0 : (var.blue_green_tg_enabled ? 2 : 1)

  alarm_name        = "${aws_lb_target_group.tg[count.index].name}-very-slow-requests"
  alarm_description = "Alarm if 1% of requests to ${aws_lb_target_group.tg[count.index].name} take longer than ${var.very_slow_request_threshold} seconds"

  actions_enabled           = true
  alarm_actions             = [var.sns_normal]
  insufficient_data_actions = []
  ok_actions                = []

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  dimensions = {
    "LoadBalancer" = aws_lb.main.arn_suffix
    "TargetGroup"  = aws_lb_target_group.tg[count.index].arn_suffix
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.very_slow_request_threshold

  datapoints_to_alarm = 1
  evaluation_periods  = 1
  extended_statistic  = "p99"
  period              = 86400
  treat_missing_data  = "notBreaching"

  tags = var.tags
}
