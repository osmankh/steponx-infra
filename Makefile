# StepOnX Infrastructure - Local Development Makefile
# Usage: make <target> [ENV=dev|prod] [PROFILE=your-profile] [REGION=eu-central-1]

PROFILE  ?= osman-admin
REGION   ?= eu-central-1
ENV      ?= production
BUCKET    = steponx-terraform-state
LOCK_TABLE = steponx-terraform-locks

# Common tofu flags for S3 backend
BACKEND_common = \
	-backend-config="bucket=$(BUCKET)" \
	-backend-config="key=$(ENV)/common/terraform.tfstate" \
	-backend-config="region=$(REGION)" \
	-backend-config="dynamodb_table=$(LOCK_TABLE)" \
	-backend-config="encrypt=true"

BACKEND_backend = \
	-backend-config="bucket=$(BUCKET)" \
	-backend-config="key=$(ENV)/backend/terraform.tfstate" \
	-backend-config="region=$(REGION)" \
	-backend-config="dynamodb_table=$(LOCK_TABLE)" \
	-backend-config="encrypt=true"

VARFILE_common  = -var-file="../../environments/$(ENV)/common.tfvars"
VARFILE_backend = -var-file="../../environments/$(ENV)/backend.tfvars"

export AWS_PROFILE=$(PROFILE)
export AWS_REGION=$(REGION)

.PHONY: bootstrap-init bootstrap-plan bootstrap-apply \
        common-init common-plan common-apply \
        backend-init backend-plan backend-apply \
        fmt validate

# ---------------------------------------------------------------------------
# Bootstrap (one-time setup)
# ---------------------------------------------------------------------------
bootstrap-init:
	cd bootstrap && tofu init

bootstrap-plan: bootstrap-init
	cd bootstrap && tofu plan -out=bootstrap.tfplan

bootstrap-apply: bootstrap-plan
	cd bootstrap && tofu apply bootstrap.tfplan

# ---------------------------------------------------------------------------
# Common Stack
# ---------------------------------------------------------------------------
common-init:
	cd stacks/common && tofu init $(BACKEND_common)

common-plan: common-init
	cd stacks/common && tofu plan $(VARFILE_common) -out=plan.tfplan

common-apply: common-plan
	cd stacks/common && tofu apply plan.tfplan

# ---------------------------------------------------------------------------
# Backend Stack
# ---------------------------------------------------------------------------
backend-init:
	cd stacks/backend && tofu init $(BACKEND_backend)

backend-plan: backend-init
	cd stacks/backend && tofu plan $(VARFILE_backend) -out=plan.tfplan

backend-apply: backend-plan
	cd stacks/backend && tofu apply plan.tfplan

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
fmt:
	tofu fmt -recursive

validate:
	cd bootstrap && tofu validate
	cd stacks/common && tofu validate
	cd stacks/backend && tofu validate
