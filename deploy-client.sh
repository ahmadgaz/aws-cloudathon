#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting client deployment script${NC}"

# Parse --local flag
LOCAL_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--local" ]]; then
    LOCAL_MODE=true
  fi
  # Remove the flag from positional parameters
  shift
  set -- "$@"
done

# Variables
REGION="us-east-1"
BUCKET_NAME="demo-bucket-123456-oliver-202406"

# LocalStack settings
if $LOCAL_MODE; then
  AWS_CMD="awslocal"
  export AWS_ACCESS_KEY_ID=test
  export AWS_SECRET_ACCESS_KEY=test
  export AWS_DEFAULT_REGION=$REGION
else
  AWS_CMD="aws"
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Fetch ALB LocalStack URL from Terraform outputs (for API base URL)
if $LOCAL_MODE; then
  RAW_URL=$(cd "$SCRIPT_DIR/infra" && terraform output -raw alb_us_east_1_localstack_url)
  # Remove any accidental repeated domain fragments
  API_BASE_URL=$(echo "$RAW_URL" | sed 's/\(\.elb\.localhost\.localstack\.cloud\)\+/.elb.localhost.localstack.cloud/')
else
  API_BASE_URL="" # Set your production API base URL here if needed
fi

# Move to client directory
cd "$SCRIPT_DIR/client" || { echo "Client directory not found"; exit 1; }

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
npm ci
echo -e "${GREEN}Dependencies installed successfully${NC}"

# Build client with API base URL
if [ -n "$API_BASE_URL" ]; then
  echo -e "${YELLOW}Building client with API base URL: $API_BASE_URL${NC}"
  VITE_API_BASE_URL="$API_BASE_URL" npm run build
else
  echo -e "${YELLOW}Building client with default API base URL${NC}"
  npm run build
fi
echo -e "${GREEN}Client built successfully${NC}"

# Deploy to S3
echo -e "${YELLOW}Deploying to S3...${NC}"
$AWS_CMD s3 sync dist/ "s3://${BUCKET_NAME}/" --delete --region ${REGION}
echo -e "${GREEN}Successfully deployed to S3${NC}"

# Get CloudFront distribution ID from Terraform output
echo -e "${YELLOW}Getting CloudFront distribution ID from Terraform output...${NC}"
CLOUDFRONT_DIST_ID=$(cd "$SCRIPT_DIR/infra" && terraform output -raw cloudfront_distribution_id)
if [[ -z $CLOUDFRONT_DIST_ID ]]; then
  echo -e "${YELLOW}Could not find CloudFront distribution ID from Terraform output. Skipping cache invalidation.${NC}"
  exit 0
fi

# Invalidate CloudFront cache
echo -e "${YELLOW}Invalidating CloudFront cache with distribution ID: ${CLOUDFRONT_DIST_ID}...${NC}"
$AWS_CMD cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DIST_ID} --paths "/*" --region ${REGION}
echo -e "${GREEN}Successfully invalidated CloudFront cache${NC}"

echo -e "${GREEN}Client deployment completed successfully!${NC}" 