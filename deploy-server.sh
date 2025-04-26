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
IMAGE_TAG="latest"

# Move to server directory
cd "$(dirname "$0")/server" || { echo "Server directory not found"; exit 1; }

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t "${ACCOUNT_ID}.dkr.ecr.${REGION_EAST}.amazonaws.com/${REPO_NAME_EAST}:${IMAGE_TAG}" .
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
echo -e "${YELLOW}Updating ECS service in ${REGION_EAST}...${NC}"
aws ecs update-service --cluster "${REGION_EAST}-ecs-cluster" --service "${REGION_EAST}-app-service" --force-new-deployment --region ${REGION_EAST}
echo -e "${GREEN}Successfully updated ECS service in ${REGION_EAST}${NC}"

echo -e "${YELLOW}Updating ECS service in ${REGION_WEST}...${NC}"
aws ecs update-service --cluster "${REGION_WEST}-ecs-cluster" --service "${REGION_WEST}-app-service" --force-new-deployment --region ${REGION_WEST}
echo -e "${GREEN}Successfully updated ECS service in ${REGION_WEST}${NC}"

echo -e "${GREEN}Server deployment completed successfully!${NC}" 