#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# AWS Profile
AWS_PROFILE="cloudathon"

echo -e "${YELLOW}This script will import existing resources into Terraform state.${NC}"
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ $confirm != "y" ]]; then
  echo -e "${YELLOW}Operation cancelled.${NC}"
  exit 0
fi

# Import AWS Secrets Manager Secret in us-west-2
SECRET_WEST_ID=$(aws secretsmanager list-secrets --profile ${AWS_PROFILE} --region us-west-2 --query "SecretList[?Name=='us-west-2-db-secret-new'].ARN" --output text)
if [ -n "$SECRET_WEST_ID" ] && [ "$SECRET_WEST_ID" != "None" ]; then
  echo -e "${YELLOW}Importing Secret in us-west-2: $SECRET_WEST_ID${NC}"
  terraform import -var-file=terraform.tfvars aws_secretsmanager_secret.db_secret_us_west_2 $SECRET_WEST_ID
  echo -e "${GREEN}Successfully imported Secret in us-west-2${NC}"
fi

# Import ALB in us-east-1
ALB_EAST_ID=$(aws elbv2 describe-load-balancers --profile ${AWS_PROFILE} --region us-east-1 --names us-east-1-public-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
if [ -n "$ALB_EAST_ID" ] && [ "$ALB_EAST_ID" != "None" ]; then
  echo -e "${YELLOW}Importing ALB in us-east-1: $ALB_EAST_ID${NC}"
  terraform import -var-file=terraform.tfvars module.alb_us_east_1.aws_lb.public $ALB_EAST_ID
  echo -e "${GREEN}Successfully imported ALB in us-east-1${NC}"
fi

# Import Target Group in us-east-1
TG_EAST_ID=$(aws elbv2 describe-target-groups --profile ${AWS_PROFILE} --region us-east-1 --names us-east-1-tg --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ -n "$TG_EAST_ID" ] && [ "$TG_EAST_ID" != "None" ]; then
  echo -e "${YELLOW}Importing Target Group in us-east-1: $TG_EAST_ID${NC}"
  terraform import -var-file=terraform.tfvars module.alb_us_east_1.aws_lb_target_group.app $TG_EAST_ID
  echo -e "${GREEN}Successfully imported Target Group in us-east-1${NC}"
fi

# Import S3 Bucket
echo -e "${YELLOW}Importing S3 Bucket: demo-bucket-123456-oliver-202406${NC}"
terraform import -var-file=terraform.tfvars module.s3_cloudfront.aws_s3_bucket.static demo-bucket-123456-oliver-202406
echo -e "${GREEN}Successfully imported S3 Bucket${NC}"

# Import WAF WebACL in us-east-1
echo -e "${YELLOW}Getting WAF details for us-east-1...${NC}"
WAF_ID=$(aws wafv2 list-web-acls --profile ${AWS_PROFILE} --region us-east-1 --scope REGIONAL --query "WebACLs[?Name=='us-east-1-waf'].Id" --output text)
WAF_NAME=$(aws wafv2 list-web-acls --profile ${AWS_PROFILE} --region us-east-1 --scope REGIONAL --query "WebACLs[?Name=='us-east-1-waf'].Name" --output text)

if [ -n "$WAF_ID" ] && [ "$WAF_ID" != "None" ] && [ -n "$WAF_NAME" ] && [ "$WAF_NAME" != "None" ]; then
  echo -e "${YELLOW}Importing WAF WebACL in us-east-1: $WAF_ID / $WAF_NAME${NC}"
  terraform import -var-file=terraform.tfvars module.waf_us_east_1.aws_wafv2_web_acl.main "$WAF_ID/$WAF_NAME/REGIONAL"
  echo -e "${GREEN}Successfully imported WAF WebACL in us-east-1${NC}"
fi

# Import DB Subnet Group in us-east-1
echo -e "${YELLOW}Importing DB Subnet Group in us-east-1: us-east-1-db-subnet-group${NC}"
terraform import -var-file=terraform.tfvars module.rds_us_east_1.aws_db_subnet_group.main us-east-1-db-subnet-group
echo -e "${GREEN}Successfully imported DB Subnet Group in us-east-1${NC}"

# Import DB Proxy in us-east-1
echo -e "${YELLOW}Importing DB Proxy in us-east-1: us-east-1-db-proxy${NC}"
terraform import -var-file=terraform.tfvars module.rds_us_east_1.aws_db_proxy.main us-east-1-db-proxy
echo -e "${GREEN}Successfully imported DB Proxy in us-east-1${NC}"

echo -e "${YELLOW}Running terraform plan to check for any remaining issues...${NC}"
terraform plan -var-file=terraform.tfvars -out=tfplan

echo -e "${GREEN}Import script completed.${NC}"
echo -e "${YELLOW}Review the plan output above for any remaining issues.${NC}"
echo -e "${YELLOW}If the plan looks good, apply it with: terraform apply tfplan${NC}" 