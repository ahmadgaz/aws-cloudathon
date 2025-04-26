#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will fix duplicate resource issues by importing existing resources into Terraform state.${NC}"
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ $confirm != "y" ]]; then
  echo -e "${YELLOW}Operation cancelled.${NC}"
  exit 0
fi

echo -e "${YELLOW}Removing state lock if present...${NC}"
rm -f .terraform.tfstate.lock.info

# Check if fix_rds_password.tf exists and remove it
if [ -f "fix_rds_password.tf" ]; then
  echo -e "${YELLOW}Removing fix_rds_password.tf file...${NC}"
  rm -f fix_rds_password.tf
  echo -e "${GREEN}Removed fix_rds_password.tf${NC}"
fi

# Check if the special password fix is already in region_us_west_2.tf
if grep -q "special = false" region_us_west_2.tf; then
  echo -e "${GREEN}Password fix already applied in region_us_west_2.tf${NC}"
else
  # Modify the existing region_us_west_2.tf file
  echo -e "${YELLOW}Updating random_password in region_us_west_2.tf...${NC}"
  sed -i.bak 's/length  = 32/length  = 16/' region_us_west_2.tf
  sed -i.bak 's/special = true/special = false/' region_us_west_2.tf
  rm -f region_us_west_2.tf.bak
  echo -e "${GREEN}Updated random_password in region_us_west_2.tf${NC}"
fi

echo -e "${YELLOW}Importing existing resources...${NC}"

# First, let's get resource IDs from AWS
echo -e "${YELLOW}Getting resource IDs from AWS...${NC}"

# Get us-east-1 ECR repository
echo -e "${YELLOW}Checking for ECR Repository in us-east-1...${NC}"
# Using repository name directly instead of ARN for import
if aws ecr describe-repositories --profile cloudathon --region us-east-1 --repository-names us-east-1-app-repo &>/dev/null; then
  echo -e "${GREEN}Found ECR Repository: us-east-1-app-repo${NC}"
  terraform state rm module.ecr_us_east_1.aws_ecr_repository.app 2>/dev/null || true
  terraform import module.ecr_us_east_1.aws_ecr_repository.app us-east-1-app-repo
fi

# Get us-east-1 Secret
SECRET_EAST=$(aws secretsmanager list-secrets --profile cloudathon --region us-east-1 --query "SecretList[?Name=='us-east-1-db-secret-new'].ARN" --output text 2>/dev/null || echo "")
if [ -n "$SECRET_EAST" ] && [ "$SECRET_EAST" != "None" ]; then
  echo -e "${GREEN}Found Secret: $SECRET_EAST${NC}"
  terraform state rm aws_secretsmanager_secret.db_secret_us_east_1 2>/dev/null || true
  terraform import aws_secretsmanager_secret.db_secret_us_east_1 $SECRET_EAST
fi

# Get us-west-2 Secret
SECRET_WEST=$(aws secretsmanager list-secrets --profile cloudathon --region us-east-1 --query "SecretList[?Name=='us-west-2-db-secret-new'].ARN" --output text 2>/dev/null || echo "")
if [ -n "$SECRET_WEST" ] && [ "$SECRET_WEST" != "None" ]; then
  echo -e "${GREEN}Found Secret: $SECRET_WEST${NC}"
  terraform state rm aws_secretsmanager_secret.db_secret_us_west_2 2>/dev/null || true
  terraform import aws_secretsmanager_secret.db_secret_us_west_2 $SECRET_WEST
fi

# Get ALB
ALB_EAST=$(aws elbv2 describe-load-balancers --profile cloudathon --region us-east-1 --query "LoadBalancers[?contains(LoadBalancerName, 'us-east-1-public-alb')].LoadBalancerArn" --output text 2>/dev/null || echo "")
if [ -n "$ALB_EAST" ] && [ "$ALB_EAST" != "None" ]; then
  echo -e "${GREEN}Found ALB: $ALB_EAST${NC}"
  terraform state rm module.alb_us_east_1.aws_lb.public 2>/dev/null || true
  terraform import module.alb_us_east_1.aws_lb.public $ALB_EAST
fi

# Get Target Group
TG_EAST=$(aws elbv2 describe-target-groups --profile cloudathon --region us-east-1 --query "TargetGroups[?contains(TargetGroupName, 'us-east-1-tg')].TargetGroupArn" --output text 2>/dev/null || echo "")
if [ -n "$TG_EAST" ] && [ "$TG_EAST" != "None" ]; then
  echo -e "${GREEN}Found Target Group: $TG_EAST${NC}"
  terraform state rm module.alb_us_east_1.aws_lb_target_group.app 2>/dev/null || true
  terraform import module.alb_us_east_1.aws_lb_target_group.app $TG_EAST
fi

# Get S3 bucket
if aws s3api head-bucket --profile cloudathon --bucket demo-bucket-123456-oliver-202406 --region us-east-1 &>/dev/null; then
  echo -e "${GREEN}Found S3 Bucket: demo-bucket-123456-oliver-202406${NC}"
  terraform state rm module.s3_cloudfront.aws_s3_bucket.static 2>/dev/null || true
  terraform import module.s3_cloudfront.aws_s3_bucket.static demo-bucket-123456-oliver-202406
fi

# Get DB Subnet Group
DB_SUBNET_GROUP=$(aws rds describe-db-subnet-groups --profile cloudathon --region us-east-1 --query "DBSubnetGroups[?DBSubnetGroupName=='us-east-1-db-subnet-group'].DBSubnetGroupName" --output text 2>/dev/null || echo "")
if [ -n "$DB_SUBNET_GROUP" ] && [ "$DB_SUBNET_GROUP" != "None" ]; then
  echo -e "${GREEN}Found DB Subnet Group: $DB_SUBNET_GROUP${NC}"
  terraform state rm module.rds_us_east_1.aws_db_subnet_group.main 2>/dev/null || true
  terraform import module.rds_us_east_1.aws_db_subnet_group.main $DB_SUBNET_GROUP
fi

# Get WAF WebACL
WAF_EAST=$(aws wafv2 list-web-acls --profile cloudathon --region us-east-1 --scope REGIONAL --query "WebACLs[?contains(Name, 'us-east-1-waf')].ARN" --output text 2>/dev/null || echo "")
if [ -n "$WAF_EAST" ] && [ "$WAF_EAST" != "None" ]; then
  echo -e "${GREEN}Found WAF WebACL: $WAF_EAST${NC}"
  terraform state rm module.waf_us_east_1.aws_wafv2_web_acl.main 2>/dev/null || true
  WAF_ID=$(echo $WAF_EAST | sed 's/.*webacl\///')
  terraform import module.waf_us_east_1.aws_wafv2_web_acl.main $WAF_ID,REGIONAL
fi

echo -e "${YELLOW}Setting up terraform.tfvars to avoid prompting for variables...${NC}"
cat > terraform.tfvars << EOF
ecs_execution_role_arn_us_east_1 = "arn:aws:iam::037297136404:role/AdminRole"
ecs_execution_role_arn_us_west_2 = "arn:aws:iam::037297136404:role/AdminRole"
ecs_task_role_arn_us_east_1 = "arn:aws:iam::037297136404:role/AdminRole"
ecs_task_role_arn_us_west_2 = "arn:aws:iam::037297136404:role/AdminRole"
EOF

echo -e "${YELLOW}Resources imported. Running Terraform plan to identify remaining issues...${NC}"
terraform plan -out=tfplan

echo -e "${GREEN}Fix completed.${NC}"
echo -e "${YELLOW}Review the plan output above for any remaining issues.${NC}"
echo -e "${YELLOW}If the plan looks good, apply it with: terraform apply tfplan${NC}" 