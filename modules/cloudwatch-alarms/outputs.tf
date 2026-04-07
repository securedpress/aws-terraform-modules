output "ecs_cpu_alarm_arn" {
  description = "ARN of the ECS CPU high alarm."
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
}

output "ecs_memory_alarm_arn" {
  description = "ARN of the ECS memory high alarm."
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
}

output "ecs_task_count_alarm_arn" {
  description = "ARN of the ECS running task count low alarm."
  value       = aws_cloudwatch_metric_alarm.ecs_task_count_low.arn
}

output "rds_cpu_alarm_arn" {
  description = "ARN of the RDS CPU high alarm. Empty string if db_instance_id not provided."
  value       = var.db_instance_id != "" ? aws_cloudwatch_metric_alarm.rds_cpu_high[0].arn : ""
}

output "rds_connections_alarm_arn" {
  description = "ARN of the RDS high connections alarm. Empty string if db_instance_id not provided."
  value       = var.db_instance_id != "" ? aws_cloudwatch_metric_alarm.rds_connections_high[0].arn : ""
}

output "rds_storage_alarm_arn" {
  description = "ARN of the RDS low free storage alarm. Empty string if db_instance_id not provided."
  value       = var.db_instance_id != "" ? aws_cloudwatch_metric_alarm.rds_free_storage_low[0].arn : ""
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications."
  value       = local.sns_topic_arn
}

output "alarm_names" {
  description = "Map of alarm type to alarm name for reference in dashboards or runbooks."
  value = {
    ecs_cpu_high       = aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name
    ecs_memory_high    = aws_cloudwatch_metric_alarm.ecs_memory_high.alarm_name
    ecs_task_count_low = aws_cloudwatch_metric_alarm.ecs_task_count_low.alarm_name
  }
}
