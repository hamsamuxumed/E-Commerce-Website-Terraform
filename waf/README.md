# AWS WAF Terraform Module

## Overview

This module configures a WAFv2 web ACL and rule groups. The scope of the web ACL can be configured as regional or global (for use with CloudFront).

The web ACL is configured with a set of AWS managed rule groups, as well as custom rule groups. Some of these rules are configured by passing in variables to the Terraform module. For more information about rules, please see the sections below.

Each WAFv2 web ACL has 1500 web ACL capacity units (WCU) available, and each configured rule group consumes some of the available WCUs. The rules deployed by this module should not exceed the 1500 WCU limit even if all rule groups are enabled.

----

## General information about rule groups

### AWS Managed Rules

These are a set of AWS WAF rules curated and maintained by the AWS Threat Research Team that provides protection against common application vulnerabilities or other unwanted traffic, without having to write your own rules. You can select and add some of the AWS managed rule groups to protect your application from various threats.

For more information on AWS managed rules, see the AWS documentation: [AWS Managed Rules rule groups list](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html)

**Various AWS Managed Rules are configured by this module.**

### AWS Marketplace rules

On the AWS Marketplace, you can find rules created by security partners that have built their own rule sets on AWS WAF. These rules are available based on subscription and can be used together with AWS Managed Rules and your own custom rules.

**No AWS Marketplace rules are configured by this module.**

### Custom rules

You can write custom rules specific to your application to block undesired patterns in parts of the HTTP request, such as headers, method, query string, Uniform Resource Identifier (URI), body, and IP address. You can use these rules together with the AWS Managed Rules groups to provide customized protections.

**Some custom rules are configured by this module.**

----

## Specific information about rule groups and rules configured by this module

### AWSManagedRulesCommonRuleSet

The Core rule set (CRS) rule group contains rules that are generally applicable to web applications. This provides protection against exploitation of a wide range of vulnerabilities, including some of the high risk and commonly occurring vulnerabilities described in OWASP publications such as OWASP Top 10.

This rule group is always enabled by the module.

### AWSManagedRulesKnownBadInputsRuleSet

The Known bad inputs rule group contains rules to block request patterns that are known to be invalid and are associated with exploitation or discovery of vulnerabilities. This can help reduce the risk of a malicious actor discovering a vulnerable application.

This rule group is always enabled by the module.

### AWSManagedRulesAmazonIpReputationList

The Amazon IP reputation list rule group contains rules that are based on Amazon internal threat intelligence. This is useful if you would like to block IP addresses typically associated with bots or other threats.

This rule group is always enabled by the module.

### AWSManagedRulesSQLiRuleSet

The SQL database rule group contains rules to block request patterns associated with exploitation of SQL databases, like SQL injection attacks.

This rule group is enabled by default, but can be optionally disabled with the `sql_rule_enabled` variable.

### AWSManagedRulesLinuxRuleSet

The Linux operating system rule group contains rules that block request patterns associated with the exploitation of vulnerabilities specific to Linux, including Linux-specific Local File Inclusion (LFI) attacks.

This rule group is disabled by default, but is enabled if the `backend_server_type` variable is set to `linux`.

### AWSManagedRulesUnixRuleSet

The POSIX operating system rule group contains rules that block request patterns associated with the exploitation of vulnerabilities specific to POSIX and POSIX-like operating systems, including Local File Inclusion (LFI) attacks.

This rule group is disabled by default, but is enabled if the `backend_server_type` variable is set to `linux`.

### AWSManagedRulesWindowsRuleSet

The Windows operating system rule group contains rules that block request patterns associated with the exploitation of vulnerabilities specific to Windows, like remote execution of PowerShell commands.

This rule group is disabled by default, but is enabled if the `backend_server_type` variable is set to `windows`.

### allowlist-ipv4

Allows any CIDR to be whitelisted. A list of CIDRs can be passed to the Terraform module with the `allowlist_addresses` variable.

### denylist-ipv4

Allows any CIDR to be blacklisted. A list of CIDRs can be passed to the Terraform module with the `denylist_addresses` variable.

### block-url-pattern-regex

Blocks any requests containing `.php`, `.cgi`, `.env`, `.aspx`, `.htaccess`, `.exe`, `.bak`, `cgi-bin` or `wp-admin`

### geo-denylist

Blocks IPs from specified geographic regions. A list of ISO 3166 alpha-2 country codes (eg `RU`, `CN`) can be passed to the Terraform module with the `denylist_geos` variable. For a list of country codes, see: https://docs.aws.amazon.com/waf/latest/APIReference/API_GeoMatchStatement.html

### rate-limit

Blocks any IP which exceeds the specified number of requests in a 5 min period. The threshold number of requests can be passed to the Terraform module with the `rate_limit` variable.

----

## Example configuration

### Regional WAF

```terraform
module "waf_regional" {
  source = "./modules/aws-waf/"


  name = "foobar-regional"

  web_acl_scope = "REGIONAL" // This is the default, included here for clarity
  allowlist_addresses = ["84.64.77.163/32"]
  denylist_addresses = ["91.218.114.206/32"]
  denylist_geos = ["RU", "CN"]
  backend_server_type = "linux"

  tags = {
    application = "foobar"
    environment = "dev"
    managed-by = "terraform"
  }
}
```

### CloudFront / Global WAF

If the `web_acl_scope` is `CLOUDFRONT` then the Web ACL resources must be created in region us-east-1. You can do this by setting your provider to deploy all resources into this region by default. Alternatively, you can configure a provider alias in your root module and then specify this provider alias per module to give you more control over which region the modules are created in. This is shown in the example below.

```terraform
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}

module "waf_cloudfront" {
  source = "./modules/aws-waf/"
  providers = {
    aws = aws.us-east-1 // Web ACL must be created in us-east-1 to use scope CLOUDFRONT
  }

  name = "foobar-cloudfront"
  web_acl_scope = "CLOUDFRONT"

  tags = {
    application = "foobar"
    environment = "dev"
    managed-by = "terraform"
  }
}
```

----

## Logging and Monitoring

### Logging

This module will enable request sampling for the Web ACL. This will record the details of a sample of the processed requests. For each sampled request, you can view detailed data about the request, such as the originating IP address and the headers included in the request. You can also view the rules that matched the request, and the rule action settings. This is a useful means to gain some visibility into what requests the Web ACL is blocking or allowing.

However it may become necessary to enable full logging of all requests. This is not configured by this module. AWS WAF can be configured to log requests to CloudWatch Logs, S3 or Kinesis Data Firehose. Care should be taken about enabling logging, as large amounts of requests (particularly during a DOS attack) could generate lots of logs and this could incur costs.

To give some pointers - logging configuration could be added using the [aws-resource-wafv2-loggingconfiguration](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-wafv2-loggingconfiguration.html) Terraform resource. For example:

```terraform
resource "aws_wafv2_web_acl_logging_configuration" "logging" {
  log_destination_configs = [aws_s3_bucket.waf_logs_bucket.arn]
  resource_arn            = module.waf_regional.web_acl_arn
}
```

### Monitoring

This module will configure each rule to send metrics to CloudWatch, so you can view near-real-time metrics for AllowedRequests, BlockedRequests, and PassedRequests for each rule.

This module also configures CloudWatch alarms to monitor the BlockedRequests for each rule. The alarms will trigger when the metric exceeds a specified static threshold. These thresholds may need to be adjusted to make the alarms more or less sensitive, you can do this by supplying the following variables to the module:

```text
rate_limit_cloudwatch_alarm_threshold
block_urls_cloudwatch_alarm_threshold
common_rules_cloudwatch_alarm_threshold
known_bad_inputs_cloudwatch_alarm_threshold
sql_injection_cloudwatch_alarm_threshold
ip_reputation_cloudwatch_alarm_threshold
unix_cloudwatch_alarm_threshold
linux_cloudwatch_alarm_threshold
windows_cloudwatch_alarm_threshold
```

When the CloudWatch alarm triggers, it will notify an SNS topic which the module creates for the purpose. The ARN of the SNS topic is output by the module as `sns_topic_arn` and `sns_topic_id`. If you wish to subscribe to the SNS topic (eg an email address), then you must do so manually.

You may also wish to configure CloudWatch dashboards to display these metrics to help with visibility, this is not configured by this module.

----

## Further information

- [AWS Documentation: AWS Managed Rules rule groups list](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html)
- [AWS Whitepaper: Guidelines for
Implementing AWS WAF](https://docs.aws.amazon.com/pdfs/whitepapers/latest/guidelines-for-implementing-aws-waf/guidelines-for-implementing-aws-waf.pdf)
