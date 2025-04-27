#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse --local flag
LOCAL_FLAG=""
for arg in "$@"; do
  if [[ "$arg" == "--local" ]]; then
    LOCAL_FLAG="--local"
  fi
  # Remove the flag from positional parameters
  shift
  set -- "$@"
done

# Use awslocal if --local is set, otherwise use aws
if [[ "$LOCAL_FLAG" == "--local" ]]; then
    AWS_CMD="awslocal"
else
    AWS_CMD="aws"
fi

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}       Full Deployment Script for CloudAthon 2025        ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Check AWS CLI is installed
if ! command -v $AWS_CMD &> /dev/null; then
    echo -e "${RED}$AWS_CMD CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install it first.${NC}"
    exit 1
fi

# Check Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed. Please install it first.${NC}"
    exit 1
fi

if [[ "$LOCAL_FLAG" == "--local" ]]; then
    echo -e "${YELLOW}Running in LocalStack mode. Skipping AWS credentials check.${NC}"
    # Optionally check LocalStack health
    if ! curl -s http://localhost:4566/_localstack/health | grep '"services"' > /dev/null; then
        echo -e "${RED}LocalStack is not running or not healthy on port 4566.${NC}"
        exit 1
    fi
    echo -e "${GREEN}LocalStack is running and healthy${NC}"
else
    echo -e "${YELLOW}Checking AWS credentials...${NC}"
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}AWS credentials not configured or invalid. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}AWS credentials are valid${NC}"
fi

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
while true; do
    echo -e "\n${BLUE}What would you like to deploy?${NC}"
    echo -e "1) ${YELLOW}Everything (server & client)${NC}"
    echo -e "2) ${YELLOW}Server only${NC}"
    echo -e "3) ${YELLOW}Client only${NC}"
    echo -e "4) ${YELLOW}Exit${NC}"
    
    read -p "Enter your choice (1-4): " deployment_choice
    
    case $deployment_choice in
        1)
            echo -e "\n${BLUE}=========================================================${NC}"
            echo -e "${BLUE}                Deploying Server & Client               ${NC}"
            echo -e "${BLUE}=========================================================${NC}"
            
            # Deploy server
            bash "${SCRIPT_DIR}/deploy-server.sh" $LOCAL_FLAG
            
            # Deploy client
            bash "${SCRIPT_DIR}/deploy-client.sh" $LOCAL_FLAG
            
            echo -e "\n${GREEN}Full deployment completed successfully!${NC}"
            ;;
        2)
            echo -e "\n${BLUE}=========================================================${NC}"
            echo -e "${BLUE}                   Deploying Server                    ${NC}"
            echo -e "${BLUE}=========================================================${NC}"
            
            # Deploy server
            bash "${SCRIPT_DIR}/deploy-server.sh" $LOCAL_FLAG
            ;;
        3)
            echo -e "\n${BLUE}=========================================================${NC}"
            echo -e "${BLUE}                   Deploying Client                    ${NC}"
            echo -e "${BLUE}=========================================================${NC}"
            
            # Deploy client
            bash "${SCRIPT_DIR}/deploy-client.sh" $LOCAL_FLAG
            ;;
        4)
            echo -e "${GREEN}Exiting deployment script.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a number between 1 and 4.${NC}"
            ;;
    esac
    
    echo -e "\n${BLUE}Deployment operations completed.${NC}"
    if ask_for_choice "Would you like to perform another deployment?"; then
        continue
    else
        echo -e "${GREEN}Exiting deployment script.${NC}"
        break
    fi
done 