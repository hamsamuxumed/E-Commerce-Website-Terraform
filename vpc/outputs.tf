output "vpc_id" {
  value = aws_vpc.main.id
}

output "availability_zone_names" {
  description = "List of availability zone names of the subnets"
  value       = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public.*.id
}
