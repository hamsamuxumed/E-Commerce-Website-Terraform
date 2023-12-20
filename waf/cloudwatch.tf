# SNS topic used to receive alerts from CloudWatch
#
# Subscriptions to this topic are not created by Terraform and should be added manually if desired
resource "aws_sns_topic" "waf_alerts" {
  name = "${var.name}-alerts-sns"
  tags = var.tags
}

#
# Cloudwatch alarms for individual WAF rules. The thresholds may need to be tweaked if they are too sensitive (or not sensitive enough!)
#
# Alarms are not created for ip-denylist and geo-denylist as we expect these to potentially block high numbers of requests.
#
resource "aws_cloudwatch_metric_alarm" "cw_rate_limit" {
  alarm_name                = "cloudwatch-alarm-${var.name}-rate-limit"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-rate-limit"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.rate_limit_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of IPs blocked on the WAF for breaching the rate limit threshold"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_block_urls" {
  alarm_name                = "cloudwatch-alarm-${var.name}-block-urls"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-block-urls"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.block_urls_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked based on the URL block regex"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_common_rules" {
  alarm_name                = "cloudwatch-alarm-${var.name}-common-rules"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-common-rules"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.common_rules_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked by AWSManagedRulesCommonRuleSet"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_known_bad_inputs" {
  alarm_name                = "cloudwatch-alarm-${var.name}-known-bad-inputs"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-known-bad-inputs"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.known_bad_inputs_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked by AWSManagedRulesKnownBadInputsRuleSet"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_sql_injection" {
  for_each = var.sql_rule_enabled == true ? toset(["dummy"]) : toset([])
  alarm_name                = "cloudwatch-alarm-${var.name}-sql-injection"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-sql-injection"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.sql_injection_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked by AWSManagedRulesSQLiRuleSet"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_ip_reputation" {
  alarm_name                = "cloudwatch-alarm-${var.name}-ip-reputation"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-ip-reputation"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.ip_reputation_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked based on the IP reputation"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_unix" {
  for_each = var.backend_server_type == "linux" ? toset(["dummy"]) : toset([])
  alarm_name                = "cloudwatch-alarm-${var.name}-unix"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-unix"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.unix_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked by AWSManagedRulesUnixRuleSet"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_linux" {
  for_each = var.backend_server_type == "linux" ? toset(["dummy"]) : toset([])
  alarm_name                = "cloudwatch-alarm-${var.name}-linux"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-linux"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.linux_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked by AWSManagedRulesLinuxRuleSet"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cw_windows" {
  for_each = var.backend_server_type == "windows" ? toset(["dummy"]) : toset([])
  alarm_name                = "cloudwatch-alarm-${var.name}-windows"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  dimensions = {
    Rule = "${var.name}-windows"
    WebACL = aws_wafv2_web_acl.waf_acl.name
  }
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.windows_cloudwatch_alarm_threshold
  alarm_description         = "This metric monitors the number of WAF requests blocked by AWSManagedRulesWindowsRuleSet"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.waf_alerts.arn]
  tags = var.tags
}