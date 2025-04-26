#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}WARNING: This script will modify your Terraform files!${NC}"
echo -e "${YELLOW}This will update your Terraform configurations to skip creating resources that already exist.${NC}"
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

echo -e "${YELLOW}Removing S3 and CloudFront resources...${NC}"
terraform state rm module.s3_cloudfront.aws_s3_bucket.static 2>/dev/null || true
terraform state rm module.s3_cloudfront.aws_s3_bucket_policy.static 2>/dev/null || true
terraform state rm module.s3_cloudfront.aws_s3_bucket_public_access_block.static 2>/dev/null || true
terraform state rm module.s3_cloudfront.aws_s3_bucket_ownership_controls.static 2>/dev/null || true
terraform state rm module.s3_cloudfront.aws_cloudfront_distribution.cdn 2>/dev/null || true
terraform state rm module.s3_cloudfront.aws_cloudfront_origin_access_identity.oai 2>/dev/null || true

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

# Backup current files
echo -e "${YELLOW}Backing up Terraform files...${NC}"
cp region_us_east_1.tf region_us_east_1.tf.bak
cp main.tf main.tf.bak

# Update the region_us_east_1.tf file to comment out conflicting modules
echo -e "${YELLOW}Updating region_us_east_1.tf to comment out conflicting modules...${NC}"
cat > region_us_east_1.tf << EOF
module "network_us_east_1" {
  source              = "./modules/network"
  providers           = { aws = aws.us_east_1 }
  region              = "us-east-1"
  cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  azs                 = ["us-east-1a", "us-east-1b"]
}

module "ecr_us_east_1" {
  source    = "./modules/ecr"
  providers = { aws = aws.us_east_1 }
  region    = "us-east-1"
}

resource "random_password" "db_password_us_east_1" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_secret_us_east_1" {
  provider = aws.us_east_1
  name = "us-east-1-db-secret-new"
}

resource "aws_secretsmanager_secret_version" "db_secret_version_us_east_1" {
  provider = aws.us_east_1
  secret_id     = aws_secretsmanager_secret.db_secret_us_east_1.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password_us_east_1.result
  })
}

# The following resources are commented out because they already exist in AWS
# and were causing conflicts during Terraform apply.

/* 
module "rds_us_east_1" {
  source                = "./modules/rds"
  providers             = { aws = aws.us_east_1 }
  region                = "us-east-1"
  db_subnet_ids         = module.network_us_east_1.public_subnet_ids
  db_security_group_ids = [module.network_us_east_1.security_group_id]
  engine                = "aurora-postgresql"
  engine_version        = "15.4"
  master_username       = "dbadmin"
  master_password       = random_password.db_password_us_east_1.result
  instance_count        = 1
  instance_class        = "db.t3.medium"
  engine_family         = "POSTGRESQL"
  proxy_role_arn        = "arn:aws:iam::037297136404:role/AdminRole"
  db_secret_arn         = aws_secretsmanager_secret.db_secret_us_east_1.arn
}

module "alb_us_east_1" {
  source                = "./modules/alb"
  providers             = { aws = aws.us_east_1 }
  region                = "us-east-1"
  public_subnet_ids     = module.network_us_east_1.public_subnet_ids
  alb_security_group_ids = [module.network_us_east_1.security_group_id]
  vpc_id                = module.network_us_east_1.vpc_id
}
*/

module "ecs_us_east_1" {
  source                = "./modules/ecs"
  providers             = { aws = aws.us_east_1 }
  region                = "us-east-1"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "arn:aws:iam::037297136404:role/AdminRole"
  task_role_arn         = "arn:aws:iam::037297136404:role/AdminRole"
  container_definitions = <<DEFINITION
[
  {
    "name": "server-container",
    "image": "${module.ecr_us_east_1.repository_url}:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      { "containerPort": 3000, "hostPort": 3000 }
    ],
    "environment": [
      { "name": "DATABASE_URL", "value": "us-east-1-db-proxy.proxy-cnydijhk2zan.us-east-1.rds.amazonaws.com" },
      { "name": "NODE_ENV", "value": "production" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "us-east-1",
        "awslogs-group": "/ecs/server-app",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
  desired_count         = 1
  subnet_ids            = module.network_us_east_1.public_subnet_ids
  security_group_ids    = [module.network_us_east_1.security_group_id]
  target_group_arn      = "arn:aws:elasticloadbalancing:us-east-1:037297136404:targetgroup/us-east-1-tg/b65b48d473644421"
  container_name        = "server-container"
  container_port        = 3000
  lb_dependency         = "dummy-dependency"
}

/*
module "waf_us_east_1" {
  source    = "./modules/waf"
  providers = { aws = aws.us_east_1 }
  region    = "us-east-1"
  alb_arn   = module.alb_us_east_1.alb_arn
}
*/
EOF

# Update main.tf to comment out s3_cloudfront module
echo -e "${YELLOW}Updating main.tf to comment out s3_cloudfront module...${NC}"
cat > main.tf << EOF
/* The following resources are commented out because they already exist in AWS
and were causing conflicts during Terraform apply.

module "s3_cloudfront" {
  source      = "./modules/s3_cloudfront"
  providers   = { aws = aws.us_east_1 }
  bucket_name = "demo-bucket-123456-oliver-202406"
}
*/
EOF

# Remove any overrides.tf file to avoid conflicts
echo -e "${YELLOW}Removing overrides.tf if it exists...${NC}"
rm -f overrides.tf

echo -e "${YELLOW}Running terraform init to refresh providers...${NC}"
terraform init -reconfigure

echo -e "${GREEN}Cleanup completed.${NC}"
echo -e "${YELLOW}You can now run 'terraform plan' and 'terraform apply' safely.${NC}"
echo -e "${YELLOW}The existing resources in AWS will not be modified or deleted.${NC}"
echo -e "${YELLOW}Backups of your original files have been saved as *.bak${NC}" 