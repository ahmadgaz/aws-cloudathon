#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting client deployment script${NC}"

# Variables
REGION="us-east-1"
BUCKET_NAME="demo-bucket-123456-oliver-202406"

# Move to client directory
cd "$(dirname "$0")/client" || { echo "Client directory not found"; exit 1; }

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
npm ci
echo -e "${GREEN}Dependencies installed successfully${NC}"

# Build client
echo -e "${YELLOW}Building client...${NC}"
npm run build
echo -e "${GREEN}Client built successfully${NC}"

# Deploy to S3
echo -e "${YELLOW}Deploying to S3...${NC}"
aws s3 sync dist/ "s3://${BUCKET_NAME}/" --delete --region ${REGION}
echo -e "${GREEN}Successfully deployed to S3${NC}"

# Get CloudFront distribution ID
echo -e "${YELLOW}Getting CloudFront distribution ID...${NC}"
DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, '${BUCKET_NAME}') || Origins.Items && contains(Origins.Items[].DomainName, '${BUCKET_NAME}')] | [0].Id" --output text --region ${REGION})

if [[ $DISTRIBUTION_ID == "None" || -z $DISTRIBUTION_ID ]]; then
  # Fallback: try to find by origin domain name, but only if Origins.Items exists
  DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items && contains(Origins.Items[].DomainName, '${BUCKET_NAME}')] | [0].Id" --output text --region ${REGION})
fi

if [[ $DISTRIBUTION_ID == "None" || -z $DISTRIBUTION_ID ]]; then
  echo -e "${YELLOW}Could not automatically find CloudFront distribution ID. Listing all distributions:${NC}"
  aws cloudfront list-distributions --query "DistributionList.Items[].{Id:Id, Domain:DomainName, Origins:Origins.Items[].DomainName}" --output table --region ${REGION}
  
  read -p "Enter the CloudFront distribution ID manually: " DISTRIBUTION_ID
  if [[ -z $DISTRIBUTION_ID ]]; then
    echo -e "${YELLOW}No distribution ID provided. Skipping cache invalidation.${NC}"
    exit 0
  fi
fi

# Invalidate CloudFront cache
echo -e "${YELLOW}Invalidating CloudFront cache with distribution ID: ${DISTRIBUTION_ID}...${NC}"
aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*" --region ${REGION}
echo -e "${GREEN}Successfully invalidated CloudFront cache${NC}"

echo -e "${GREEN}Client deployment completed successfully!${NC}" 