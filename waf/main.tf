###
# For AWS managed rules, see:
#     https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html
#
# Generic useful rule sets include:
#
#   - AWSManagedRulesCommonRuleSet (i.e. "core rule set"); WCU 700
#   - AWSManagedRulesKnownBadInputsRuleSet; WCU 200
#   - AWSManagedRulesSQLiRuleSet; WCU 200
#   - AWSManagedRulesAmazonIpReputationList; WCU 25
#
# For Windows-based environments, also add:
#   - AWSManagedRulesWindowsRuleSet; WCU 200
#
# For Linux, also add:
#   - AWSManagedRulesLinuxRuleSet; WCU 200
#   - AWSManagedRulesUnixRuleSet; WCU 100

##

terraform {
  required_providers {
    aws = { // us-east-1 is required for WAFv2 resources on scope CLOUDFRONT
      source = "hashicorp/aws"
    }
  }
}

resource "aws_wafv2_ip_set" "allowlist" {
  # Included in Terraform so simple to enable in an emergency:
  # pass in addresses using variable.
  name               = "${var.name}-allowlist-ipv4"
  description        = "Denied IPs"
  scope              = var.web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.allowlist_addresses

  tags = merge({
    "Name" = "${var.name}-allowlist-ipv4"
  }, var.tags)
}

resource "aws_wafv2_ip_set" "denylist" {
  # Included in Terraform so simple to enable in an emergency:
  # pass in addresses using variable.
  name               = "${var.name}-denylist-ipv4"
  description        = "Blocked IPs"
  scope              = var.web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.denylist_addresses

  tags = merge({
    "Name" = "${var.name}-denylist-ipv4"
  }, var.tags)
}

resource "aws_wafv2_regex_pattern_set" "block_urls" {
  name        = "${var.name}-block-url-pattern-regex"
  description = "Blocked URL patterns and file extensions"
  scope       = var.web_acl_scope

  regular_expression {
    regex_string = "^.*(\\\\.(php|cgi|env|aspx|htaccess|exe|bak)|cgi-bin|wp-admin).*"
  }

  tags = merge({
    "Name" = "${var.name}-block-urls"
  }, var.tags)
}

resource "aws_wafv2_web_acl" "waf_acl" {
  name        = "${var.name}-web-acl"
  description = "Web ACL"
  scope       = var.web_acl_scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "${var.name}-web-acl"
  }

  tags = merge({
    "Name" = "${var.name}-web-acl"
  }, var.tags)

  # allowlist only included if non-empty (charged per-rule, so worth excluding).
  # The 'rule' is included 0 or 1 times. Inside the 'rule' is what is in 'content'.
  # Can't use 'count' for the nested 'rule' block; hence resorting to complicated 'dynamic'.
  dynamic "rule" {
    for_each = length(var.allowlist_addresses) > 0 ? ["dummy"] : []
    content {
      name     = "ip-allowlist"
      priority = 0
      action {
        allow {}
      }
      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowlist.arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${var.name}-ip-allowlist"
      }
    }
  }

  # denylist only included if non-empty (charged per-rule, so worth excluding).
  # The 'rule' is included 0 or 1 times. Inside the 'rule' is what is in 'content'.
  # Can't use 'count' for the nested 'rule' block; hence resorting to complicated 'dynamic'.
  dynamic "rule" {
    for_each = length(var.denylist_addresses) > 0 ? ["dummy"] : []
    content {
      name     = "ip-denylist"
      priority = 10
      action {
        block {}
      }
      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.denylist.arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${var.name}-ip-denylist"
      }
    }
  }

  # denylist only included if non-empty (charged per-rule, so worth excluding).
  # The 'rule' is included 0 or 1 times. Inside the 'rule' is what is in 'content'.
  # Can't use 'count' for the nested 'rule' block; hence resorting to complicated 'dynamic'.
  dynamic "rule" {
    for_each = length(var.denylist_geos) > 0 ? ["dummy"] : []
    content {
      name     = "geo-denylist"
      priority = 11
      action {
        block {}
      }
      statement {
        geo_match_statement {
          country_codes = var.denylist_geos
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${var.name}-geo-denylist"
      }
    }
  }

  // Rate limiting: if `limit` requests per 5 minutes timespan from a given IP, then block.
  // See https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html
  //
  // WARNING: If WAF is on a load balancer with a CDN infront of it, then be careful about source-IPs.
  // Consider using "Forwarded IP configuration" to look at X-Forwarded-For.
  rule {
    name     = "rate-limit"
    priority = 20
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-rate-limit"
    }
  }

  rule {
    name     = "block-urls"
    priority = 30
    action {
      block {}
    }
    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.block_urls.arn
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-block-urls"
    }
  }

  rule {
    name     = "managed-common-rules"
    priority = 40
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-common-rules"
    }
  }

  rule {
    name     = "known-bad-inputs-rules"
    priority = 41
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-known-bad-inputs"
    }
  }

  dynamic "rule" {
    for_each = var.sql_rule_enabled == true ? ["dummy"] : []
    content {
      name     = "sql-injection"
      priority = 42
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesSQLiRuleSet"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${var.name}-sql-injection"
      }
    }
  }

  rule {
    name     = "ip-reputation-rules"
    priority = 43
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-ip-reputation"
    }
  }

  # unix-rules only included if backend is 'linux'.
  # The 'rule' is included 0 or 1 times. Inside the 'rule' is what is in 'content'.
  # Can't use 'count' for the nested 'rule' block; hence resorting to complicated 'dynamic'.
  dynamic "rule" {
    for_each = var.backend_server_type == "linux" ? ["dummy"] : []
    content {
      name     = "unix-rules"
      priority = 44
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesUnixRuleSet"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${var.name}-unix"
      }
    }
  }

  # linux-rules only included if backend is 'linux'.
  # The 'rule' is included 0 or 1 times. Inside the 'rule' is what is in 'content'.
  # Can't use 'count' for the nested 'rule' block; hence resorting to complicated 'dynamic'.
  dynamic "rule" {
    for_each = var.backend_server_type == "linux" ? ["dummy"] : []
    content {
      name     = "linux-rules"
      priority = 45
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesLinuxRuleSet"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${var.name}-linux"
      }
    }
  }

  # windows-rules only included if backend is 'windows'.
  # The 'rule' is included 0 or 1 times. Inside the 'rule' is what is in 'content'.
  # Can't use 'count' for the nested 'rule' block; hence resorting to complicated 'dynamic'.
  dynamic "rule" {
    for_each = var.backend_server_type == "windows" ? ["dummy"] : []
    content {
      name     = "windows-rules"
      priority = 46
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = "AWSManagedRulesWindowsRuleSet"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${var.name}-windows"
      }
    }
  }
}
