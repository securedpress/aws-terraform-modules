variable "identifier" {
  description = "Unique identifier for the RDS instance. Used as the DB instance ID."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.identifier))
    error_message = "identifier must be lowercase alphanumeric and hyphens only."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "RDS instance class. Use db.t3.micro for dev, db.t3.medium+ for staging/production."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GiB. Set to 0 to disable autoscaling."
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the initial database to create."
  type        = string
}

variable "database_username" {
  description = "Master username for the database."
  type        = string
  default     = "dbadmin"
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability. Recommended true for production."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups. 0 disables backups."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 0 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 0 and 35."
  }
}

variable "backup_window" {
  description = "Daily time range for automated backups (UTC). e.g. '03:00-04:00'"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window. e.g. 'Mon:04:00-Mon:05:00'"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection. Set to true for production databases."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion. Set to false for production."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption. Uses AWS managed key if not specified."
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment. Affects defaults for deletion_protection and Multi-AZ."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be deployed."
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to port 5432."
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
