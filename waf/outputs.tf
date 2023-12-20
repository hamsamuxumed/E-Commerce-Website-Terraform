output "web_acl_arn" {
  value = aws_wafv2_web_acl.waf_acl.arn
}

output "web_acl_id" {
  value = aws_wafv2_web_acl.waf_acl.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.waf_alerts.arn
}

output "sns_topic_id" {
  value = aws_sns_topic.waf_alerts.id
}
