#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Importing existing us-east-1 resources into Terraform state...${NC}"

# Import ECR repository
echo -e "${YELLOW}Importing ECR repository...${NC}"
terraform import module.ecr_us_east_1.aws_ecr_repository.app us-east-1-app-repo

# Import ECS cluster
echo -e "${YELLOW}Importing ECS cluster...${NC}"
terraform import module.ecs_us_east_1.aws_ecs_cluster.main arn:aws:ecs:us-east-1:037297136404:cluster/us-east-1-ecs-cluster

# Import VPC and networking resources
echo -e "${YELLOW}Importing VPC and network resources...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=us-east-1-vpc" --query "Vpcs[0].VpcId" --output text --region us-east-1)
terraform import module.network_us_east_1.aws_vpc.main $VPC_ID

# Import subnets
SUBNET_IDS=($(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text --region us-east-1))
terraform import module.network_us_east_1.aws_subnet.public[0] ${SUBNET_IDS[0]}
terraform import module.network_us_east_1.aws_subnet.public[1] ${SUBNET_IDS[1]}

# Import security group
SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=us-east-1-main-sg" --query "SecurityGroups[0].GroupId" --output text --region us-east-1)
terraform import module.network_us_east_1.aws_security_group.main $SG_ID

# Import internet gateway
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text --region us-east-1)
terraform import module.network_us_east_1.aws_internet_gateway.gw $IGW_ID

# Import ALB resources
ALB_ARN=$(aws elbv2 describe-load-balancers --names "us-east-1-public-alb" --query "LoadBalancers[0].LoadBalancerArn" --output text --region us-east-1)
terraform import module.alb_us_east_1.aws_lb.public $ALB_ARN

TG_ARN=$(aws elbv2 describe-target-groups --names "us-east-1-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region us-east-1)
terraform import module.alb_us_east_1.aws_lb_target_group.app $TG_ARN

# Import listeners
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query "Listeners[0].ListenerArn" --output text --region us-east-1)
terraform import module.alb_us_east_1.aws_lb_listener.http $LISTENER_ARN

# Import RDS resources
DB_SUBNET_GROUP=$(aws rds describe-db-subnet-groups --db-subnet-group-name "us-east-1-db-subnet-group" --query "DBSubnetGroups[0].DBSubnetGroupName" --output text --region us-east-1)
terraform import module.rds_us_east_1.aws_db_subnet_group.main $DB_SUBNET_GROUP

# Import WAF
WAF_ID=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[?Name=='us-east-1-waf'].Id" --output text --region us-east-1)
terraform import "module.waf_us_east_1.aws_wafv2_web_acl.main" "$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[?Name=='us-east-1-waf'].Id" --output text --region us-east-1)|us-east-1-waf|REGIONAL"

echo -e "${GREEN}Resources imported successfully!${NC}"
echo -e "${YELLOW}Now try running terraform plan to verify state...${NC}"