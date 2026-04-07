# aws-terraform-modules

Production-grade, reusable Terraform modules for AWS infrastructure.
Designed for regulated environments — financial services, healthtech, pharma.

Built and maintained by [SecuredPress LLC](https://securedpress.com)

---

## Modules

| Module | Description | Terraform Docs |
|---|---|---|
| [ecs-fargate](./modules/ecs-fargate) | ECS Fargate service with ALB, autoscaling, Secrets Manager | [README](./modules/ecs-fargate/README.md) |
| [rds-postgres](./modules/rds-postgres) | RDS PostgreSQL with blue/green, Multi-AZ, encryption | [README](./modules/rds-postgres/README.md) |
| [cloudwatch-alarms](./modules/cloudwatch-alarms) | Standardized CloudWatch alarms for ECS + RDS workloads | [README](./modules/cloudwatch-alarms/README.md) |

---

## Design Principles

**Least privilege by default** — every module ships with a minimal IAM role scoped to the resources it manages. No `*` actions.

**No long-lived credentials** — all examples use OIDC for GitHub Actions. See [examples/complete-stack](./examples/complete-stack).

**Encrypted at rest and in transit** — KMS encryption enabled by default on RDS. ALB enforces HTTPS. Secrets Manager for all credentials.

**Tagging enforced** — every resource receives `Project`, `Environment`, `ManagedBy`, and `Owner` tags. Missing required tags fail at plan time.

---

## Usage

### Standalone module

```hcl
module "api_service" {
  source = "github.com/securedpress/aws-terraform-modules//modules/ecs-fargate"

  service_name = "my-api"
  image        = "123456789.dkr.ecr.us-east-1.amazonaws.com/my-api:latest"
  cpu          = 512
  memory       = 1024
  min_tasks    = 2
  max_tasks    = 10
  environment  = "staging"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  public_subnets  = module.vpc.public_subnet_ids

  tags = {
    Project   = "my-project"
    Owner     = "platform-team"
  }
}
```

### Complete stack (ECS + RDS + Alarms)

See [examples/complete-stack](./examples/complete-stack) for a full working example
combining all three modules with shared VPC, security groups, and Secrets Manager.

---

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.7 |
| aws provider | >= 5.0 |

---

## Examples

- [ecs-fargate](./examples/ecs-fargate) — Standalone Fargate service with ALB
- [rds-postgres](./examples/rds-postgres) — RDS PostgreSQL with automated backups
- [complete-stack](./examples/complete-stack) — Full stack: ECS + RDS + CloudWatch alarms

---

## Related Repositories

- [aws-infra-agent](https://github.com/securedpress/aws-infra-agent) — AI agent that generates Terraform using these modules via AWS Bedrock
- [sagemaker-autopilot-demo](https://github.com/securedpress/sagemaker-autopilot-demo) — ML pipeline on AWS SageMaker

---

## License

MIT — see [LICENSE](LICENSE)
