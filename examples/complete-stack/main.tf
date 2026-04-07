# Example: Complete Stack
#
# Demonstrates all three modules working together:
#   - ECS Fargate service (API)
#   - RDS PostgreSQL (database)
#   - CloudWatch alarms wired to Lambda auto-remediation
#
# Usage:
#   terraform init
#   terraform plan -var-file="staging.tfvars"
#   terraform apply -var-file="staging.tfvars"

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    # Configure via -backend-config or environment variables
    # bucket         = "your-tf-state-bucket"
    # key            = "examples/complete-stack/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "your-tf-lock-table"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ─── ECS Fargate Service ────────────────────────────────────────────────────

module "api" {
  source = "../../modules/ecs-fargate"

  service_name = "${local.name_prefix}-api"
  image        = var.api_image
  cpu          = var.api_cpu
  memory       = var.api_memory
  min_tasks    = var.api_min_tasks
  max_tasks    = var.api_max_tasks
  environment  = var.environment

  vpc_id          = var.vpc_id
  private_subnets = var.private_subnet_ids
  public_subnets  = var.public_subnet_ids

  secrets_manager_arns = [
    module.database.db_secret_arn,
  ]

  environment_variables = {
    APP_ENV      = var.environment
    DB_HOST      = module.database.db_host
    DB_PORT      = tostring(module.database.db_port)
    DB_NAME      = module.database.db_name
  }
}

# ─── RDS PostgreSQL ─────────────────────────────────────────────────────────

module "database" {
  source = "../../modules/rds-postgres"

  identifier    = "${local.name_prefix}-db"
  database_name = replace(var.project_name, "-", "_")
  environment   = var.environment

  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  multi_az              = var.environment == "production"
  deletion_protection   = var.environment == "production"
  skip_final_snapshot   = var.environment != "production"

  vpc_id          = var.vpc_id
  private_subnets = var.private_subnet_ids

  allowed_security_group_ids = [
    module.api.service_security_group_id,
  ]
}

# ─── CloudWatch Alarms ──────────────────────────────────────────────────────

module "alarms" {
  source = "../../modules/cloudwatch-alarms"

  service_name     = module.api.service_name
  ecs_cluster_name = module.api.cluster_name
  db_instance_id   = module.database.db_instance_id
  environment      = var.environment

  enable_remediation     = true
  remediation_lambda_arn = aws_lambda_function.remediator.arn
}

# ─── Remediation Lambda ─────────────────────────────────────────────────────
# Reference implementation — in production use the aws-infra-agent Lambda module

data "archive_file" "remediator" {
  type        = "zip"
  source_file = "${path.module}/remediation_handler.py"
  output_path = "${path.module}/.build/remediation_handler.zip"
}

resource "aws_lambda_function" "remediator" {
  function_name = "${local.name_prefix}-remediator"
  role          = aws_iam_role.lambda_remediator.arn
  handler       = "remediation_handler.handler"
  runtime       = "python3.12"
  timeout       = 30

  filename         = data.archive_file.remediator.output_path
  source_code_hash = data.archive_file.remediator.output_base64sha256

  environment {
    variables = {
      ECS_CLUSTER_NAME = module.api.cluster_name
      SNS_TOPIC_ARN    = module.alarms.sns_topic_arn
      MAX_TASKS        = tostring(var.api_max_tasks)
    }
  }
}
