terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  name_prefix = "${var.service_name}-${var.environment}"

  sns_topic_arn = var.sns_topic_arn != "" ? var.sns_topic_arn : aws_sns_topic.this[0].arn

  common_tags = merge(
    {
      Service     = var.service_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ── SNS Topic ─────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "this" {
  count = var.sns_topic_arn == "" ? 1 : 0

  name = "${local.name_prefix}-alarms"
  tags = local.common_tags
}

# ── ECS Alarms ────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "ecs-cpu-high-${local.name_prefix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_threshold_high
  alarm_description   = "ECS CPU utilization high for ${var.service_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "ecs-memory-high-${local.name_prefix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_threshold_high
  alarm_description   = "ECS memory utilization high for ${var.service_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_count_low" {
  alarm_name          = "ecs-task-count-low-${local.name_prefix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.task_count_min
  alarm_description   = "ECS running task count low for ${var.service_name}"
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [local.sns_topic_arn]

  tags = local.common_tags
}

# ── RDS Alarms (optional) ─────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.db_instance_id != "" ? 1 : 0

  alarm_name          = "rds-cpu-high-${local.name_prefix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold_high
  alarm_description   = "RDS CPU utilization high for ${var.db_instance_id}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  count = var.db_instance_id != "" ? 1 : 0

  alarm_name          = "rds-connections-high-${local.name_prefix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_connections_threshold
  alarm_description   = "RDS connections high for ${var.db_instance_id}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [local.sns_topic_arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  count = var.db_instance_id != "" ? 1 : 0

  alarm_name          = "rds-storage-low-${local.name_prefix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_free_storage_threshold_gb * 1024 * 1024 * 1024
  alarm_description   = "RDS free storage low for ${var.db_instance_id}"
  treat_missing_data  = "breaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [local.sns_topic_arn]

  tags = local.common_tags
}

# ── EventBridge → Lambda Remediation (optional) ───────────────────────────────

resource "aws_cloudwatch_event_rule" "alarm_state_change" {
  count = var.enable_remediation && var.remediation_lambda_arn != "" ? 1 : 0

  name        = "${local.name_prefix}-alarm-remediation"
  description = "Trigger Lambda remediation on CloudWatch alarm state change"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = { value = ["ALARM"] }
      alarmName = [
        { prefix = "ecs-cpu-high-${local.name_prefix}" },
        { prefix = "ecs-memory-high-${local.name_prefix}" },
        { prefix = "ecs-task-count-low-${local.name_prefix}" },
      ]
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = var.enable_remediation && var.remediation_lambda_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.alarm_state_change[0].name
  target_id = "remediation-lambda"
  arn       = var.remediation_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count = var.enable_remediation && var.remediation_lambda_arn != "" ? 1 : 0

  statement_id  = "AllowEventBridgeInvoke-${local.name_prefix}"
  action        = "lambda:InvokeFunction"
  function_name = var.remediation_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_state_change[0].arn
}
