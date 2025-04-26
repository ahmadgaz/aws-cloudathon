#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will completely reset your Terraform state.${NC}"
echo -e "${RED}WARNING: This will delete all existing resources tracked by Terraform.${NC}"
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ $confirm != "y" ]]; then
  echo -e "${YELLOW}Operation cancelled.${NC}"
  exit 0
fi

echo -e "${YELLOW}Cleaning Terraform state files...${NC}"
rm -f .terraform.tfstate.lock.info
rm -f terraform.tfstate
rm -f terraform.tfstate.backup
rm -f terraform.tfstate.*.backup

echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init -reconfigure

echo -e "${GREEN}Terraform environment cleaned and initialized.${NC}"
echo -e "${YELLOW}You can now run 'terraform plan' and 'terraform apply'${NC}" 