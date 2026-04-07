# Module: rds-postgres

Deploys a production-ready RDS PostgreSQL instance with:

- Automated password rotation via AWS Secrets Manager
- Storage encryption with KMS (AWS managed or customer managed key)
- Storage autoscaling
- Automated backups with configurable retention
- Performance Insights enabled by default
- Subnet group scoped to private subnets only
- Security group — allows inbound 5432 from specified security groups only

---

## Usage

```hcl
module "database" {
  source = "github.com/securedpress/aws-terraform-modules//modules/rds-postgres"

  identifier    = "payments-db"
  database_name = "payments"
  environment   = "production"

  instance_class        = "db.t3.medium"
  engine_version        = "15.4"
  allocated_storage     = 50
  max_allocated_storage = 200
  multi_az              = true
  deletion_protection   = true
  skip_final_snapshot   = false

  vpc_id          = var.vpc_id
  private_subnets = var.private_subnet_ids

  allowed_security_group_ids = [
    module.api.service_security_group_id,
  ]

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
| `identifier` | RDS instance identifier | `string` | — | yes |
| `database_name` | Initial database name | `string` | — | yes |
| `engine_version` | PostgreSQL version | `string` | `15.4` | no |
| `instance_class` | RDS instance class | `string` | `db.t3.micro` | no |
| `allocated_storage` | Initial storage in GiB | `number` | `20` | no |
| `max_allocated_storage` | Max storage for autoscaling | `number` | `100` | no |
| `multi_az` | Enable Multi-AZ | `bool` | `false` | no |
| `backup_retention_days` | Backup retention (0–35 days) | `number` | `7` | no |
| `deletion_protection` | Prevent accidental deletion | `bool` | `false` | no |
| `skip_final_snapshot` | Skip snapshot on destroy | `bool` | `true` | no |
| `kms_key_id` | Customer managed KMS key ARN | `string` | `null` | no |
| `environment` | dev / staging / production | `string` | `staging` | no |
| `vpc_id` | Target VPC ID | `string` | — | yes |
| `private_subnets` | Private subnet IDs for DB subnet group | `list(string)` | — | yes |
| `allowed_security_group_ids` | SGs allowed to connect on port 5432 | `list(string)` | `[]` | no |
| `performance_insights_enabled` | Enable Performance Insights | `bool` | `true` | no |
| `tags` | Additional resource tags | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|---|---|
| `db_instance_id` | RDS instance identifier |
| `db_instance_arn` | RDS instance ARN |
| `db_endpoint` | Connection endpoint (host:port) |
| `db_host` | Hostname only |
| `db_port` | Port (default 5432) |
| `db_name` | Database name |
| `db_secret_arn` | Secrets Manager ARN for master password |
| `db_security_group_id` | RDS security group ID |
| `db_subnet_group_name` | DB subnet group name |
| `db_multi_az` | Whether Multi-AZ is enabled |

---

## Security Notes

- Master password is **never stored in Terraform state** — generated and stored in Secrets Manager on creation
- Storage encrypted at rest — uses AWS managed key by default, pass `kms_key_id` for CMEK
- RDS instance is deployed in **private subnets only** — no public accessibility
- Port 5432 inbound restricted to explicitly listed security groups
- Set `deletion_protection = true` and `skip_final_snapshot = false` for all production databases
