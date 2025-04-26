#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will fix the provider issue with us-west-2 resources.${NC}"
echo -e "${RED}WARNING: This will reset your Terraform state.${NC}"
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ $confirm != "y" ]]; then
  echo -e "${YELLOW}Operation cancelled.${NC}"
  exit 0
fi

echo -e "${YELLOW}Removing state lock if present...${NC}"
rm -f .terraform.tfstate.lock.info

echo -e "${YELLOW}Moving resources created in us-east-1 that should be in us-west-2...${NC}"

# List resources that need to be removed
resources=$(terraform state list | grep west | grep -v "module.waf\|module.ecr\|module.network")
if [ -n "$resources" ]; then
  echo -e "${YELLOW}Found the following us-west-2 resources in wrong region:${NC}"
  echo "$resources"
  
  # Remove these resources from state
  echo -e "${YELLOW}Removing these resources from state...${NC}"
  for res in $resources; do
    echo "Removing $res"
    terraform state rm "$res"
  done
else
  echo -e "${YELLOW}No us-west-2 resources found in the wrong region.${NC}"
fi

echo -e "${YELLOW}Reinitializing Terraform...${NC}"
terraform init -reconfigure

echo -e "${GREEN}Fix completed.${NC}"
echo -e "${YELLOW}You can now run 'terraform plan' and 'terraform apply' again.${NC}" 