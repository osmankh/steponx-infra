# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

OpenTofu (Terraform-compatible) infrastructure-as-code for the StepOnX e-commerce platform. Deploys to AWS `eu-central-1`. The companion application repo lives at `../steponx/`.

## Commands

All local commands use `tofu` (OpenTofu), not `terraform`. The Makefile defaults to `PROFILE=osman-admin` and `REGION=eu-central-1`.

```bash
# Format all .tf files
make fmt

# Validate all stacks
make validate

# Plan / apply a specific stack (bootstrap, common, backend)
make <stack>-init
make <stack>-plan
make <stack>-apply   # runs init + plan + apply in sequence

# Direct tofu usage (each stack is its own root module)
cd stacks/backend && tofu init && tofu plan
```

There are no tests or linters beyond `tofu validate` and `tofu fmt`.

## Architecture

Three deployment layers, applied in order:

1. **bootstrap/** — One-time foundation (local state). Creates S3 state bucket, DynamoDB lock table, GitHub Actions OIDC provider + IAM role. Applied via `workflow_dispatch` using static IAM credentials.

2. **stacks/common/** — Shared infrastructure (remote S3 state, key `common/terraform.tfstate`). VPC, S3 media bucket (CloudFront optional), SES (conditional on `domain_name`), Cognito user pool.

3. **stacks/backend/** — Application infrastructure (remote S3 state, key `backend/terraform.tfstate`). Reads common stack outputs via `terraform_remote_state`. Contains: two ECR repos (web + api), ECS Fargate cluster, ALB with host-based routing, RDS PostgreSQL, two ECS services (web on port 3000, api on port 3001), Route 53 DNS records.

### Module inventory (`modules/`)

| Module | Used by | Purpose |
|--------|---------|---------|
| `vpc` | common | VPC with public + private subnets across 2 AZs |
| `s3-cloudfront` | common | S3 bucket with optional CloudFront distribution |
| `ses` | common | SES domain identity + DKIM + sending policy |
| `cognito` | common | User pool with app client |
| `ecr` | backend | ECR repository (used twice: web + api) |
| `ecs-cluster` | backend | Fargate cluster + CloudWatch log group |
| `ecs-service` | backend | Task definition + service + auto-scaling + IAM roles |
| `alb` | backend | ALB + default target group + HTTP/HTTPS listeners |
| `rds` | backend | PostgreSQL instance + Secrets Manager credentials |

### Key patterns

- Many resources are **conditionally created** via `count` and feature flags (`enable_load_balancer`, `enable_media_bucket`, `media_cloudfront_enabled`, `create_dns_records`). Always gate dependent resources on the same flag.
- The `ecs-service` module is instantiated twice (web + api) with different `service_name` values. It uses `name_prefix` for IAM roles to avoid naming collisions.
- The `ecr` module accepts an optional `repository_name` override (used by the api repo).
- The backend stack creates its own ECS tasks security group and ALB listener rules for the API (host-header routing) outside of modules, since these cross module boundaries.
- Backend stack references common stack outputs via `data.terraform_remote_state.common` stored in `local.common`.

## CI/CD

- **`.github/workflows/deploy.yml`** — PR: plans both stacks and posts comments. Push to main: applies common then backend sequentially. Manual dispatch: choose which stack(s).
- **`.github/workflows/bootstrap.yml`** — Manual-only, uses static IAM credentials for initial bootstrap.
- Both workflows use OpenTofu ~1.9 and AWS OIDC authentication (except bootstrap).

## Conventions

- All `.tfvars` files are gitignored; defaults are set in `variables.tf`.
- State is encrypted in S3 with DynamoDB locking.
- Resource naming follows `${project_name}-${environment}-<resource>` pattern.
- Tags are passed through via a `tags` variable merged at each resource.
