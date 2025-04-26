#!/bin/bash
set -e

# AWS CLI profile to use
PROFILE="cloudathon"
REGION="us-east-1"

# Find resource ARNs and IDs
echo "Finding existing resources in ${REGION}..."

# Import load balancer
echo "Importing ALB..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names "us-east-1-public-alb" --query "LoadBalancers[0].LoadBalancerArn" --output text --region ${REGION} --profile ${PROFILE})
terraform import module.alb_us_east_1.aws_lb.public ${ALB_ARN}

# Import target group
echo "Importing target group..."
TG_ARN=$(aws elbv2 describe-target-groups --names "us-east-1-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region ${REGION} --profile ${PROFILE})
terraform import module.alb_us_east_1.aws_lb_target_group.app ${TG_ARN}

# Import DB subnet group
echo "Importing DB subnet group..."
terraform import module.rds_us_east_1.aws_db_subnet_group.main us-east-1-db-subnet-group

# Import WAF
echo "Importing WAF..."
WAF_ID=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[?Name=='us-east-1-waf'].Id" --output text --region ${REGION} --profile ${PROFILE})
if [[ -n "$WAF_ID" ]]; then
  terraform import "module.waf_us_east_1.aws_wafv2_web_acl.main" "${WAF_ID}|us-east-1-waf|REGIONAL"
fi

# Try to find ECS service
echo "Checking for ECS service..."
ECS_SERVICE=$(aws ecs list-services --cluster us-east-1-ecs-cluster --query "serviceArns[0]" --output text --region ${REGION} --profile ${PROFILE})
if [[ ${ECS_SERVICE} != "None" ]]; then
  echo "Importing ECS service..."
  terraform import module.ecs_us_east_1.aws_ecs_service.app ${ECS_SERVICE}
fi

# Try to find ECS task definition
echo "Checking for ECS task definition..."
TASK_DEF=$(aws ecs list-task-definitions --family-prefix us-east-1-app --status ACTIVE --query "taskDefinitionArns[0]" --output text --region ${REGION} --profile ${PROFILE})
if [[ ${TASK_DEF} != "None" ]]; then
  echo "Importing ECS task definition..."
  terraform import module.ecs_us_east_1.aws_ecs_task_definition.app ${TASK_DEF}
fi

echo "Import completed. Run terraform plan to check for any remaining issues."