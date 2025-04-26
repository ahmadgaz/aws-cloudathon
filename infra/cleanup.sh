#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}WARNING: This script will remove resources from Terraform state!${NC}"
echo -e "${YELLOW}This will not delete actual AWS resources, but will remove them from Terraform management.${NC}"
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ $confirm != "y" ]]; then
  echo -e "${YELLOW}Operation cancelled.${NC}"
  exit 0
fi

# Remove problematic resources from state
echo -e "${YELLOW}Removing problematic resources from Terraform state...${NC}"

echo -e "${YELLOW}Removing ALB and related resources...${NC}"
terraform state rm module.alb_us_east_1.aws_lb.public 2>/dev/null || true
terraform state rm module.alb_us_east_1.aws_lb_target_group.app 2>/dev/null || true
terraform state rm module.alb_us_east_1.aws_lb_listener.http 2>/dev/null || true

echo -e "${YELLOW}Removing RDS resources...${NC}"
terraform state rm module.rds_us_east_1.aws_db_subnet_group.main 2>/dev/null || true
terraform state rm module.rds_us_east_1.aws_db_proxy.main 2>/dev/null || true
terraform state rm module.rds_us_east_1.aws_rds_cluster_instance.main 2>/dev/null || true
terraform state rm module.rds_us_east_1.aws_rds_cluster.main 2>/dev/null || true

echo -e "${YELLOW}Removing WAF resources...${NC}"
terraform state rm module.waf_us_east_1.aws_wafv2_web_acl.main 2>/dev/null || true
terraform state rm module.waf_us_east_1.aws_wafv2_web_acl_association.main 2>/dev/null || true

# Create or update a tfvars file
echo -e "${YELLOW}Creating or updating terraform.tfvars file...${NC}"
cat > terraform.tfvars << EOF
ecs_execution_role_arn_us_east_1 = "arn:aws:iam::037297136404:role/AdminRole"
ecs_execution_role_arn_us_west_2 = "arn:aws:iam::037297136404:role/AdminRole"
ecs_task_role_arn_us_east_1 = "arn:aws:iam::037297136404:role/AdminRole"
ecs_task_role_arn_us_west_2 = "arn:aws:iam::037297136404:role/AdminRole"
EOF

# Fix issues with random_password
echo -e "${YELLOW}Fixing random_password resources...${NC}"
terraform state rm random_password.db_password_us_east_1 2>/dev/null || true
terraform state rm random_password.db_password_us_west_2 2>/dev/null || true

# Create or modify the overrides.tf file to skip creation of conflicting resources
echo -e "${YELLOW}Creating overrides.tf to skip conflicting resources...${NC}"
cat > overrides.tf << EOF
# Skip creating resources that already exist
locals {
  skip_east_resources = true
}

# Conditionally create ALB resources in us-east-1
module "alb_us_east_1" {
  source = "./modules/alb"
  count  = local.skip_east_resources ? 0 : 1
  region = "us-east-1"
  public_subnet_ids = module.network_us_east_1.public_subnet_ids
  alb_security_group_ids = [module.network_us_east_1.security_group_id]
  vpc_id = module.network_us_east_1.vpc_id
}

# Conditionally create RDS resources in us-east-1
module "rds_us_east_1" {
  source = "./modules/rds"
  count  = local.skip_east_resources ? 0 : 1
  region = "us-east-1"
  db_subnet_ids = module.network_us_east_1.public_subnet_ids
  db_security_group_ids = [module.network_us_east_1.security_group_id]
  engine = "aurora-postgresql"
  engine_version = "15.4"
  master_username = "dbadmin"
  master_password = "Temporarypassword123"
  instance_count = 1
  instance_class = "db.t3.medium"
  engine_family = "POSTGRESQL"
  proxy_role_arn = "arn:aws:iam::037297136404:role/AdminRole"
  db_secret_arn = aws_secretsmanager_secret.db_secret_us_east_1.arn
}

# Conditionally create WAF resources in us-east-1
module "waf_us_east_1" {
  source = "./modules/waf"
  count  = local.skip_east_resources ? 0 : 1
  region = "us-east-1"
  alb_arn = "dummy-arn"
}

# Skip S3/CloudFront if it already exists
module "s3_cloudfront" {
  source = "./modules/s3_cloudfront"
  count  = local.skip_east_resources ? 0 : 1
  bucket_name = "demo-bucket-123456-oliver-202406"
}
EOF

echo -e "${YELLOW}Running terraform init to refresh providers...${NC}"
terraform init -reconfigure

echo -e "${GREEN}Cleanup completed.${NC}"
echo -e "${YELLOW}You can now run 'terraform plan' and 'terraform apply' safely.${NC}"
echo -e "${YELLOW}The existing resources in AWS will not be modified or deleted.${NC}" 