# Module: cloudwatch-alarms

Standardized CloudWatch alarm set for ECS Fargate + RDS PostgreSQL workloads.

Covers:
- ECS CPU utilization (high)
- ECS memory utilization (high)
- ECS running task count (low — detects crash loops)
- RDS CPU utilization (high)
- RDS database connections (high)
- RDS free storage space (low)

Optionally wires alarms to EventBridge for Lambda auto-remediation.

---

## Usage

```hcl
module "alarms" {
  source = "github.com/securedpress/aws-terraform-modules//modules/cloudwatch-alarms"

  service_name     = module.api.service_name
  ecs_cluster_name = module.api.cluster_name
  db_instance_id   = module.database.db_instance_id
  environment      = "production"

  cpu_threshold_high            = 75
  memory_threshold_high         = 80
  rds_connections_threshold     = 200
  rds_free_storage_threshold_gb = 20

  enable_remediation     = true
  remediation_lambda_arn = aws_lambda_function.remediator.arn

  tags = {
    Project = "payments-platform"
  }
}
```

---

## Alarm Reference

| Alarm | Metric | Default Threshold | Action |
|---|---|---|---|
| `ecs-cpu-high` | ECS CPUUtilization | > 80% for 3min | Scale out |
| `ecs-memory-high` | ECS MemoryUtilization | > 85% for 3min | Scale out |
| `ecs-task-count-low` | ECS RunningTaskCount | < min_tasks | Force redeploy |
| `rds-cpu-high` | RDS CPUUtilization | > 80% for 3min | SNS notify |
| `rds-connections-high` | RDS DatabaseConnections | > 100 | SNS notify |
| `rds-storage-low` | RDS FreeStorageSpace | < 10 GiB | SNS notify |

---

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `service_name` | ECS service name to monitor | `string` | — | yes |
| `ecs_cluster_name` | ECS cluster name | `string` | — | yes |
| `db_instance_id` | RDS instance ID (skip RDS alarms if empty) | `string` | `""` | no |
| `environment` | dev / staging / production | `string` | `staging` | no |
| `sns_topic_arn` | Existing SNS topic ARN (creates new if empty) | `string` | `""` | no |
| `cpu_threshold_high` | ECS CPU % alarm threshold | `number` | `80` | no |
| `memory_threshold_high` | ECS memory % alarm threshold | `number` | `85` | no |
| `task_count_min` | Minimum expected running tasks | `number` | `1` | no |
| `rds_connections_threshold` | RDS max connections alarm threshold | `number` | `100` | no |
| `rds_free_storage_threshold_gb` | RDS free storage alarm threshold (GiB) | `number` | `10` | no |
| `enable_remediation` | Wire alarms to EventBridge + Lambda | `bool` | `true` | no |
| `remediation_lambda_arn` | Lambda ARN for auto-remediation | `string` | `""` | no |
| `tags` | Additional resource tags | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|---|---|
| `ecs_cpu_alarm_arn` | ECS CPU high alarm ARN |
| `ecs_memory_alarm_arn` | ECS memory high alarm ARN |
| `ecs_task_count_alarm_arn` | ECS task count low alarm ARN |
| `rds_cpu_alarm_arn` | RDS CPU high alarm ARN |
| `rds_connections_alarm_arn` | RDS connections high alarm ARN |
| `rds_storage_alarm_arn` | RDS low storage alarm ARN |
| `sns_topic_arn` | SNS topic ARN for notifications |
| `alarm_names` | Map of alarm type → alarm name |
