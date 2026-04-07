output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_endpoint" {
  description = "Connection endpoint in host:port format."
  value       = aws_db_instance.this.endpoint
}

output "db_host" {
  description = "Hostname of the RDS instance (without port)."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the database is listening on."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Master username."
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the master password."
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_security_group_id" {
  description = "Security group ID attached to the RDS instance."
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}

output "db_instance_class" {
  description = "Instance class of the RDS instance."
  value       = aws_db_instance.this.instance_class
}

output "db_multi_az" {
  description = "Whether the RDS instance is Multi-AZ."
  value       = aws_db_instance.this.multi_az
}
