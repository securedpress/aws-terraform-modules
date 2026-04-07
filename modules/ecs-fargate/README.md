# Module: ecs-fargate

Deploys a production-ready ECS Fargate service with:

- Application Load Balancer (HTTPS ready)
- Application Auto Scaling (CPU and memory based)
- IAM task role with least-privilege policy
- Secrets Manager integration for credentials
- CloudWatch log group with configurable retention
- Security groups (ALB → service, no direct internet access to tasks)

---

## Usage

```hcl
module "api" {
  source = "github.com/securedpress/aws-terraform-modules//modules/ecs-fargate"

  service_name = "payments-api"
  image        = "123456789.dkr.ecr.us-east-1.amazonaws.com/payments-api:v1.2.0"
  cpu          = 1024
  memory       = 2048
  min_tasks    = 2
  max_tasks    = 10
  environment  = "production"

  vpc_id          = var.vpc_id
  private_subnets = var.private_subnet_ids
  public_subnets  = var.public_subnet_ids

  secrets_manager_arns = [
    aws_secretsmanager_secret.db_password.arn,
    aws_secretsmanager_secret.api_key.arn,
  ]

  environment_variables = {
    APP_ENV  = "production"
    LOG_LEVEL = "info"
  }

  tags = {
    Project = "payments-platform"
    Owner   = "platform-team"
  }
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `service_name` | ECS service name — used as resource prefix | `string` | — | yes |
| `image` | Full ECR image URI with tag | `string` | — | yes |
| `cpu` | Task CPU units (256/512/1024/2048/4096) | `number` | `512` | no |
| `memory` | Task memory in MiB | `number` | `1024` | no |
| `min_tasks` | Autoscaling minimum tasks | `number` | `1` | no |
| `max_tasks` | Autoscaling maximum tasks | `number` | `4` | no |
| `container_port` | Port the container listens on | `number` | `8080` | no |
| `health_check_path` | ALB health check path | `string` | `/health` | no |
| `environment` | dev / staging / production | `string` | `staging` | no |
| `vpc_id` | Target VPC ID | `string` | — | yes |
| `private_subnets` | Private subnet IDs for ECS tasks | `list(string)` | — | yes |
| `public_subnets` | Public subnet IDs for ALB | `list(string)` | — | yes |
| `enable_autoscaling` | Enable Application Auto Scaling | `bool` | `true` | no |
| `enable_execute_command` | Enable ECS Exec (disable in prod) | `bool` | `false` | no |
| `secrets_manager_arns` | Secrets Manager ARNs for task role | `list(string)` | `[]` | no |
| `environment_variables` | Non-sensitive env vars | `map(string)` | `{}` | no |
| `tags` | Additional resource tags | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|---|---|
| `service_name` | ECS service name |
| `service_arn` | ECS service ARN |
| `cluster_name` | ECS cluster name |
| `cluster_arn` | ECS cluster ARN |
| `task_definition_arn` | Current task definition ARN |
| `task_role_arn` | Task IAM role ARN — attach additional policies here |
| `alb_dns_name` | ALB DNS name — use for Route53 or direct access |
| `alb_zone_id` | ALB hosted zone ID for Route53 alias records |
| `alb_security_group_id` | ALB security group ID |
| `service_security_group_id` | ECS task security group ID |
| `cloudwatch_log_group` | CloudWatch log group name |

---

## Security Notes

- ECS tasks run in **private subnets only** — no direct internet access
- ALB sits in public subnets; security group allows 443/80 inbound only
- Task security group allows inbound only from ALB security group
- Secrets Manager secrets are mounted at runtime — never baked into the image
- `enable_execute_command` defaults to `false` — enable only for debugging, never in production
