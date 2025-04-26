#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}          Infrastructure Deployment Script               ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity --profile cloudathon &> /dev/null; then
    echo -e "${RED}AWS credentials not valid for profile 'cloudathon'. Please check your AWS configuration.${NC}"
    exit 1
fi
echo -e "${GREEN}AWS credentials are valid${NC}"

# Function to ask user for choice
ask_for_choice() {
    read -p "$1 (y/n): " choice
    case "$choice" in
        y|Y ) return 0;;
        n|N ) return 1;;
        * ) echo "Please answer y or n"; ask_for_choice "$1";;
    esac
}

# Main deployment menu
echo -e "\n${BLUE}How would you like to deploy the infrastructure?${NC}"
echo -e "1) ${YELLOW}Clean Start (destroy everything and start fresh)${NC}"
echo -e "2) ${YELLOW}Fix Duplicates (import existing resources)${NC}"
echo -e "3) ${YELLOW}Continue Deployment (use current state)${NC}"
echo -e "4) ${YELLOW}Exit${NC}"

read -p "Enter your choice (1-4): " deployment_choice

case $deployment_choice in
    1)
        echo -e "\n${BLUE}=========================================================${NC}"
        echo -e "${BLUE}                Clean Start Deployment                   ${NC}"
        echo -e "${BLUE}=========================================================${NC}"
        
        echo -e "${RED}WARNING: This will destroy all existing resources!${NC}"
        if ask_for_choice "Are you sure you want to destroy all resources?"; then
            echo -e "${YELLOW}Destroying existing infrastructure...${NC}"
            terraform destroy -auto-approve
            
            echo -e "${YELLOW}Removing Terraform state...${NC}"
            rm -f terraform.tfstate*
            rm -f .terraform.tfstate.lock.info
            
            echo -e "${YELLOW}Initializing Terraform...${NC}"
            terraform init -reconfigure
            
            echo -e "${YELLOW}Planning deployment...${NC}"
            terraform plan -out=tfplan
            
            echo -e "${YELLOW}Applying plan...${NC}"
            terraform apply tfplan
        else
            echo -e "${YELLOW}Clean start cancelled.${NC}"
            exit 0
        fi
        ;;
    2)
        echo -e "\n${BLUE}=========================================================${NC}"
        echo -e "${BLUE}             Fix Duplicates Deployment                  ${NC}"
        echo -e "${BLUE}=========================================================${NC}"
        
        echo -e "${YELLOW}Running fix_duplicates script...${NC}"
        ./fix_duplicates.sh
        ;;
    3)
        echo -e "\n${BLUE}=========================================================${NC}"
        echo -e "${BLUE}               Continue Deployment                      ${NC}"
        echo -e "${BLUE}=========================================================${NC}"
        
        echo -e "${YELLOW}Planning deployment...${NC}"
        terraform plan -out=tfplan
        
        echo -e "${YELLOW}Applying plan...${NC}"
        terraform apply tfplan
        ;;
    4)
        echo -e "${GREEN}Exiting deployment script.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Please enter a number between 1 and 4.${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Deployment operations completed.${NC}" 