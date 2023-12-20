output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "target_group_arn" {
  value = aws_lb_target_group.tg[0].arn
}

output "target_group_name" {
  value = aws_lb_target_group.tg[0].name
}

output "secondary_target_group_arn" {
  value = var.blue_green_tg_enabled ? aws_lb_target_group.tg[1].arn : null
}

output "secondary_target_group_name" {
  value = var.blue_green_tg_enabled ? aws_lb_target_group.tg[1].name : null
}

output "listener_arn" {
  value = aws_lb_listener.https.arn
}

output "load_balancer_security_group_id" {
  value = aws_security_group.alb_sg.id
}
