variable "service_name" {
  description = "Name of the ECS service. Used as a prefix for all related resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service_name))
    error_message = "service_name must be lowercase alphanumeric and hyphens only."
  }
}

variable "image" {
  description = "Full ECR image URI including tag. e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/my-api:latest"
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units. Valid values: 256, 512, 1024, 2048, 4096."
  type        = number
  default     = 512

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Fargate task memory in MiB. Must be valid for the chosen cpu value."
  type        = number
  default     = 1024
}

variable "min_tasks" {
  description = "Minimum number of running tasks for autoscaling."
  type        = number
  default     = 1

  validation {
    condition     = var.min_tasks >= 1
    error_message = "min_tasks must be at least 1."
  }
}

variable "max_tasks" {
  description = "Maximum number of running tasks for autoscaling."
  type        = number
  default     = 4
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "ALB health check path."
  type        = string
  default     = "/health"
}

variable "environment" {
  description = "Deployment environment. Affects instance sizing defaults and Multi-AZ behavior."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "vpc_id" {
  description = "VPC ID where the ECS service and ALB will be deployed."
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "enable_autoscaling" {
  description = "Whether to enable Application Auto Scaling for the ECS service."
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for debugging. Disable in production."
  type        = bool
  default     = false
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs the task role should have read access to."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Non-sensitive environment variables injected into the container."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to all resources. Merged with module default tags."
  type        = map(string)
  default     = {}
}
