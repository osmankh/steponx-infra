# AWS Account Verification & Next Steps

## Account Verification

### Why Verification Is Needed

New AWS accounts have restrictions preventing creation of certain services (CloudFront, Elastic Load Balancer) until identity verification is complete. Our account (495599775261) currently has these restrictions.

### Verification Process

Complete verification through the AWS Management Console:

1. Navigate to **AWS Billing and Cost Management** console
2. Access the **Account Settings** section
3. Complete any pending verification steps:
   - Phone number verification
   - Payment method validation
   - Identity document submission (if requested)

### Alternative Verification Methods

Check the **AWS Account and Billing** console for:
- Account verification status indicators
- Required verification steps specific to your account
- Payment method validation requirements

### Console-Based Troubleshooting

1. Review account status in **Account Settings**
2. Verify payment method is valid and verified
3. Complete any pending identity verification steps
4. Check for service-specific restrictions in the **Service Quotas** console

### Service Quota Verification

Access the **Service Quotas** console to:
- Review current limits for CloudFront distributions
- Check Elastic Load Balancing quotas
- Verify if quotas are set to zero due to verification requirements

Check ELBv2 account limits:
```bash
aws elbv2 describe-account-limits --region eu-central-1
```

For CloudFront, verification status affects the ability to create new distributions rather than imposing specific quotas.

### Verification Timeline

| Type | Timeline |
|------|----------|
| Phone verification | Immediate |
| Payment method verification | 1-2 business days |
| Identity document verification | 2-5 business days |

The verification process is automated for most accounts, but some may require additional review based on account activity patterns or geographic location.

Monitor verification status through the AWS console notifications and account settings page.

### Support Case

A support case should be submitted at https://console.aws.amazon.com/support/home requesting verification for:
- **Amazon CloudFront** - CDN for product images
- **Elastic Load Balancing (ELBv2)** - Application Load Balancer for ECS Fargate

---

## Next Steps

### 1. After Account Verification

Once the account is verified, enable the disabled infrastructure:

**Enable ALB (Application Load Balancer):**
- Set `enable_load_balancer = true` in `stacks/backend/terraform.tfvars`
- Provide `alb_certificate_arn` (ACM certificate for your domain)
- Push to main - CI/CD will create the ALB and wire it to ECS

**Enable CloudFront CDN:**
- Set `enable_cdn = true` in `stacks/common/terraform.tfvars`
- Provide `cdn_acm_certificate_arn` (must be in us-east-1 for CloudFront)
- Push to main - CI/CD will create the S3 bucket + CloudFront distribution

### 2. Domain & SSL Certificates

- Request an **ACM certificate** in `eu-central-1` for ALB
- Request an **ACM certificate** in `us-east-1` for CloudFront (CloudFront requires us-east-1)
- Validate both certificates via DNS (add CNAME records)

### 3. SES Email Setup

- Set `domain_name` variable in the common stack to enable SES
- Add the **DKIM DNS records** that SES provides (3 CNAME records)
- Request **SES production access** (new accounts are in sandbox mode - can only send to verified emails)

### 4. Cognito OTP Lambda Triggers

Build and deploy 3 Lambda functions for email OTP custom auth:

| Function | Purpose |
|----------|---------|
| `DefineAuthChallenge` | Decides the auth flow steps |
| `CreateAuthChallenge` | Generates OTP and sends it via SES |
| `VerifyAuthChallengeResponse` | Validates the user's OTP input |

Wire them to the Cognito User Pool trigger configuration.

### 5. Dockerize & Deploy the Application

- Create a `Dockerfile` for the Next.js app
- Push the Docker image to ECR: `495599775261.dkr.ecr.eu-central-1.amazonaws.com/steponx-production`
- Update the ECS task definition with the real container image
- Configure environment variables:
  - `DATABASE_URL` - from RDS Secrets Manager
  - `COGNITO_USER_POOL_ID` - `eu-central-1_jtF9n5GfU`
  - `COGNITO_CLIENT_ID` - `183q335pa5vjrlhjub3ra15kli`
  - Other app-specific variables
- Set up a CI/CD pipeline in the `steponx` repo to build and deploy on push

### 6. Database Migration

- Retrieve RDS credentials from AWS Secrets Manager
- Run Drizzle migrations (`pnpm db:migrate`) against the new RDS instance
- Migrate existing data from Render PostgreSQL to RDS
- RDS endpoint: `steponx-production-postgres.cpauyacee6j3.eu-central-1.rds.amazonaws.com:5432`

### 7. DNS Cutover

- Point your domain to the ALB DNS name (or CloudFront distribution)
- Update Cognito callback/logout URLs to the production domain
- Update any hardcoded URLs in the application

---

## Current Infrastructure Status

| Resource | Status | Details |
|----------|--------|---------|
| VPC | Active | `vpc-0c0265640eec7eccc`, 2 AZs, public + private subnets |
| ECS Cluster | Active | `steponx-production-cluster` (Fargate + FARGATE_SPOT) |
| ECS Service | Running | Placeholder container |
| ECR | Active | `steponx-production` |
| RDS PostgreSQL | Active | 16.6, db.t4g.micro, encrypted |
| Cognito | Active | `eu-central-1_jtF9n5GfU` |
| CloudFront CDN | Disabled | Pending account verification |
| ALB | Disabled | Pending account verification |
| SES | Disabled | No domain configured |
