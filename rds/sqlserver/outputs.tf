output "connection_details_secret_arn" {
  value = aws_secretsmanager_secret.secret.arn
}

output "rds_identifier" {
  value = aws_db_instance.rds_instance.identifier
}
