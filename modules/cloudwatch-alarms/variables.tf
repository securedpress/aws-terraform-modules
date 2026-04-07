variable "service_name" {
  description = "Name of the ECS service to monitor. Used to construct alarm names and dimensions."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster the service runs in."
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance identifier to monitor. Leave empty to skip RDS alarms."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment. Used in alarm names and SNS topic."
  type        = string
  default     = "staging"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications. Creates a new topic if not provided."
  type        = string
  default     = ""
}

variable "cpu_threshold_high" {
  description = "ECS CPU utilization % that triggers the high alarm."
  type        = number
  default     = 80
}

variable "memory_threshold_high" {
  description = "ECS memory utilization % that triggers the high alarm."
  type        = number
  default     = 85
}

variable "task_count_min" {
  description = "Minimum expected running task count. Alarm triggers if below this value."
  type        = number
  default     = 1
}

variable "rds_cpu_threshold_high" {
  description = "RDS CPU utilization % that triggers the high alarm."
  type        = number
  default     = 80
}

variable "rds_connections_threshold" {
  description = "RDS connection count that triggers the high connections alarm."
  type        = number
  default     = 100
}

variable "rds_free_storage_threshold_gb" {
  description = "RDS free storage GiB below which the low storage alarm triggers."
  type        = number
  default     = 10
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods before alarm state changes."
  type        = number
  default     = 3
}

variable "alarm_period_seconds" {
  description = "Period in seconds for each evaluation point."
  type        = number
  default     = 60
}

variable "enable_remediation" {
  description = "Whether to wire alarms to EventBridge for Lambda auto-remediation."
  type        = bool
  default     = true
}

variable "remediation_lambda_arn" {
  description = "ARN of the Lambda remediation function. Required if enable_remediation = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
