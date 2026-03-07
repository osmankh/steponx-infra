# StepOnX Infrastructure

OpenTofu (Terraform-compatible) infrastructure-as-code for the [StepOnX](https://github.com/osmankh/steponx) e-commerce platform. Deploys to AWS `eu-central-1`.

## Architecture

```
                  ┌──────────────────────────────────────────────┐
                  │                   ALB                        │
                  │         (host-based routing)                 │
                  │                                              │
                  │   steponx.com ──► Web TG                     │
                  │   api.steponx.com ──► API TG                 │
                  └────────┬────────────────┬───────────────────-┘
                           │                │
                  ┌────────▼──────┐  ┌──────▼────────┐
                  │  ECS Service  │  │  ECS Service   │
                  │  Web (Next.js)│  │  API (Fastify) │
                  │  Port 3000    │  │  Port 3001     │
                  └───────┬───────┘  └──────┬─────────┘
                          │                 │
                          └────────┬────────┘
                                   │
                          ┌────────▼────────┐
                          │  RDS PostgreSQL  │
                          └─────────────────┘
```

Infrastructure is organized into three deployment layers, applied in order:

### 1. Bootstrap (`bootstrap/`)

One-time foundation with local state. Creates:

- S3 bucket for Terraform state (versioned, encrypted)
- DynamoDB table for state locking
- GitHub Actions OIDC provider + IAM role (trusts both `steponx-infra` and `steponx` repos)

### 2. Common (`stacks/common/`)

Shared infrastructure (remote S3 state). Creates:

- **VPC** — Public + private subnets across 2 AZs
- **S3 media bucket** — For product images/uploads (CloudFront optional)
- **SES** — Email sending (conditional on `domain_name`)
- **Cognito** — User pool with app client

### 3. Backend (`stacks/backend/`)

Application infrastructure (remote S3 state). Reads common stack outputs via `terraform_remote_state`. Creates:

- **ECR** — Two repositories (web + api)
- **ECS Fargate cluster** — With CloudWatch log group
- **ALB** — With host-based routing (root domain to web, api subdomain to API)
- **RDS PostgreSQL** — With Secrets Manager credentials
- **ECS services** — Web (Next.js, port 3000) and API (Fastify/tRPC, port 3001)
- **Route 53 DNS records** — Optional, gated by `create_dns_records`

## Modules

| Module | Purpose |
|--------|---------|
| `modules/vpc` | VPC with public + private subnets across 2 AZs |
| `modules/s3-cloudfront` | S3 bucket with optional CloudFront distribution |
| `modules/ses` | SES domain identity + DKIM + sending policy |
| `modules/cognito` | User pool with app client |
| `modules/ecr` | ECR repository |
| `modules/ecs-cluster` | Fargate cluster + CloudWatch log group |
| `modules/ecs-service` | Task definition + service + auto-scaling + IAM roles |
| `modules/alb` | ALB + target group + HTTP/HTTPS listeners |
| `modules/rds` | PostgreSQL instance + Secrets Manager credentials |

## Prerequisites

- [OpenTofu](https://opentofu.org/) ~1.9
- AWS CLI configured with a profile (default: `osman-admin`)
- S3 state bucket and DynamoDB lock table (created by bootstrap)

## Usage

All commands use the Makefile, which defaults to `PROFILE=osman-admin` and `REGION=eu-central-1`.

```bash
# Format all .tf files
make fmt

# Validate all stacks
make validate

# Bootstrap (first-time only)
make bootstrap-apply

# Deploy common infrastructure
make common-apply

# Deploy backend infrastructure
make backend-apply
```

Override defaults as needed:

```bash
make backend-plan PROFILE=my-profile REGION=us-east-1
```

Or use `tofu` directly:

```bash
cd stacks/backend
tofu init
tofu plan
tofu apply
```

## Feature Flags

Many resources are conditionally created via variables:

| Variable | Stack | Default | Description |
|----------|-------|---------|-------------|
| `enable_media_bucket` | common | `true` | Create S3 media bucket |
| `media_cloudfront_enabled` | common | `false` | Add CloudFront CDN to media bucket |
| `enable_nat_gateway` | common | `false` | NAT Gateway for private subnets |
| `enable_vpc_flow_logs` | common | `false` | VPC flow logs |
| `enable_load_balancer` | backend | `false` | Create ALB and attach ECS services |
| `create_dns_records` | backend | `false` | Create Route 53 records for ALB |

## CI/CD

Two GitHub Actions workflows:

- **`deploy.yml`** — On PR: plans both stacks and posts comments. On push to `main`: applies common then backend sequentially. Manual dispatch to choose stacks.
- **`bootstrap.yml`** — Manual-only, uses static IAM credentials for initial setup.

Both use OpenTofu ~1.9 and AWS OIDC authentication (except bootstrap).

## Conventions

- `.tfvars` files are gitignored; defaults in `variables.tf`
- State is encrypted in S3 with DynamoDB locking
- Resource naming: `${project_name}-${environment}-<resource>`
- Tags passed through via `tags` variable
