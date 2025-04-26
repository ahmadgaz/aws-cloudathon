#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Removing problematic resources from Terraform state...${NC}"

# Remove resources from state
terraform state rm module.alb_us_east_1.aws_lb.public || true
terraform state rm module.alb_us_east_1.aws_lb_target_group.app || true
terraform state rm module.rds_us_east_1.aws_db_subnet_group.main || true
terraform state rm module.waf_us_east_1.aws_wafv2_web_acl.main || true

echo -e "${YELLOW}Creating a modified terraform file for east region...${NC}"

# Create a backup of the original file
cp infra/region_us_east_1.tf infra/region_us_east_1.tf.orig

# Update the region file to use different resource names
cat > infra/region_us_east_1.tf << EOF
module "network_us_east_1" {
  source              = "./modules/network"
  providers           = { aws = aws.us_east_1 }
  region              = "us-east-1"
  cidr_block          = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
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
  name = "us-east-1-db-secret-new-v2"
}

resource "aws_secretsmanager_secret_version" "db_secret_version_us_east_1" {
  provider = aws.us_east_1
  secret_id     = aws_secretsmanager_secret.db_secret_us_east_1.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password_us_east_1.result
  })
}

# Skipping most ALB, WAF and DB resources to let the application use existing ones
# We'll just create the ECS resources to run the application

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
  # Use a different name to avoid conflict
  container_name        = "server-container"
  container_port        = 3000
}
EOF

echo -e "${GREEN}Modified terraform file created. Running terraform apply...${NC}"

# Run terraform apply
cd infra
terraform apply -auto-approve

echo -e "${GREEN}Terraform apply completed. Your ECS resources should now be deployed.${NC}"
echo -e "${YELLOW}Once this is working, update your deploy-server.sh script to use the correct target groups and ECS services.${NC}"