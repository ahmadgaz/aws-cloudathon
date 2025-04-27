#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting server deployment script${NC}"

# Variables
REGION_EAST="us-east-1"
REGION_WEST="us-west-2"
ACCOUNT_ID="037297136404"
REPO_NAME_EAST="us-east-1-app-repo"
REPO_NAME_WEST="us-west-2-app-repo"
IMAGE_TAG=$(git rev-parse --short HEAD)

# Write the image tag to a Terraform variable file for use in ECS task definition
echo "image_tag = \"$IMAGE_TAG\"" > infra/image_tag.auto.tfvars

# Move to server directory
cd "$(dirname "$0")/server" || { echo "Server directory not found"; exit 1; }

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build --platform linux/amd64 -t "${ACCOUNT_ID}.dkr.ecr.${REGION_EAST}.amazonaws.com/${REPO_NAME_EAST}:${IMAGE_TAG}" .
echo -e "${GREEN}Docker image built successfully${NC}"

# Login to ECR in us-east-1
echo -e "${YELLOW}Logging in to ECR in ${REGION_EAST}...${NC}"
aws ecr get-login-password --region ${REGION_EAST} | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION_EAST}.amazonaws.com"
echo -e "${GREEN}Successfully logged in to ECR in ${REGION_EAST}${NC}"

# Push Docker image to ECR in us-east-1
echo -e "${YELLOW}Pushing Docker image to ECR in ${REGION_EAST}...${NC}"
docker push "${ACCOUNT_ID}.dkr.ecr.${REGION_EAST}.amazonaws.com/${REPO_NAME_EAST}:${IMAGE_TAG}"
echo -e "${GREEN}Successfully pushed image to ECR in ${REGION_EAST}${NC}"

# Tag image for us-west-2
echo -e "${YELLOW}Tagging image for ${REGION_WEST}...${NC}"
docker tag "${ACCOUNT_ID}.dkr.ecr.${REGION_EAST}.amazonaws.com/${REPO_NAME_EAST}:${IMAGE_TAG}" "${ACCOUNT_ID}.dkr.ecr.${REGION_WEST}.amazonaws.com/${REPO_NAME_WEST}:${IMAGE_TAG}"

# Login to ECR in us-west-2
echo -e "${YELLOW}Logging in to ECR in ${REGION_WEST}...${NC}"
aws ecr get-login-password --region ${REGION_WEST} | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION_WEST}.amazonaws.com"
echo -e "${GREEN}Successfully logged in to ECR in ${REGION_WEST}${NC}"

# Push Docker image to ECR in us-west-2
echo -e "${YELLOW}Pushing Docker image to ECR in ${REGION_WEST}...${NC}"
docker push "${ACCOUNT_ID}.dkr.ecr.${REGION_WEST}.amazonaws.com/${REPO_NAME_WEST}:${IMAGE_TAG}"
echo -e "${GREEN}Successfully pushed image to ECR in ${REGION_WEST}${NC}"

# Update ECS services
# Note: Service names should match the ECS service names as per Terraform

# us-east-1
ECS_CLUSTER_EAST="${REGION_EAST}-ecs-cluster"
ECS_SERVICE_EAST="us-east-1-app-service"

# us-west-2
ECS_CLUSTER_WEST="${REGION_WEST}-ecs-cluster"
ECS_SERVICE_WEST="us-west-2-app-service"

echo -e "${YELLOW}Updating ECS service in ${REGION_EAST}...${NC}"
aws ecs update-service --cluster "$ECS_CLUSTER_EAST" --service "$ECS_SERVICE_EAST" --force-new-deployment --region ${REGION_EAST}
echo -e "${GREEN}Successfully updated ECS service in ${REGION_EAST}${NC}"

echo -e "${YELLOW}Updating ECS service in ${REGION_WEST}...${NC}"
aws ecs update-service --cluster "$ECS_CLUSTER_WEST" --service "$ECS_SERVICE_WEST" --force-new-deployment --region ${REGION_WEST}
echo -e "${GREEN}Successfully updated ECS service in ${REGION_WEST}${NC}"

echo -e "${GREEN}Server deployment completed successfully!${NC}"

# Automatically apply Terraform to update ECS task definition with new image tag
cd ../infra || { echo "Infra directory not found"; exit 1; }
echo -e "${YELLOW}Applying Terraform changes to update ECS task definition...${NC}"
terraform apply -auto-approve
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Terraform apply completed successfully!${NC}"
else
  echo -e "${YELLOW}Terraform apply failed. Please check the output above for errors.${NC}"
  exit 1
fi 