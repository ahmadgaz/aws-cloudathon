#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper for error exit
fail() {
  echo -e "${YELLOW}$1${NC}" >&2
  exit 1
}

echo -e "${YELLOW}Starting server deployment script${NC}"

# Parse --local flag
LOCAL_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--local" ]]; then
    LOCAL_MODE=true
  fi
  # No need to shift or reset positional parameters
  # shift
  # set -- "$@"
done

# Variables
REGION_EAST="us-east-1"
REPO_NAME_EAST="us-east-1-app-repo"
IMAGE_TAG=$(git rev-parse --short HEAD)

# LocalStack settings
if $LOCAL_MODE; then
  ECR_EAST="localhost:4510/${REPO_NAME_EAST}"
else
  ACCOUNT_ID="037297136404"
  ECR_EAST="${ACCOUNT_ID}.dkr.ecr.${REGION_EAST}.amazonaws.com/${REPO_NAME_EAST}"
fi

# Write the image tag to a Terraform variable file for use in ECS task definition
echo "image_tag = \"$IMAGE_TAG\"" > infra/image_tag.auto.tfvars

# Move to server directory
cd "$(dirname "$0")/server" || fail "Server directory not found"

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build --platform linux/amd64 -t "$ECR_EAST:$IMAGE_TAG" . || fail "Docker build failed!"
echo -e "${GREEN}Docker image built and tagged as $ECR_EAST:$IMAGE_TAG${NC}"

docker tag "$ECR_EAST:$IMAGE_TAG" "000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566/us-east-1-app-repo:$IMAGE_TAG" || fail "Docker tag (east) failed!"
docker tag "$ECR_EAST:$IMAGE_TAG" "000000000000.dkr.ecr.us-west-2.localhost.localstack.cloud:4566/us-west-2-app-repo:$IMAGE_TAG" || fail "Docker tag (west) failed!"

# Start local Postgres for LocalStack dev if not already running
if $LOCAL_MODE; then
  POSTGRES_CONTAINER_NAME="cloudathon25-postgres"
  # Extract credentials from Terraform state (global secret)
  if [ ! -f ../infra/terraform.tfstate ]; then
    fail "terraform.tfstate not found in infra directory!"
  fi
  DB_SECRET=$(jq -r '.resources[] | select(.type=="aws_secretsmanager_secret_version" and .name=="db_secret_version_global") | .instances[0].attributes.secret_string' ../infra/terraform.tfstate)
  if [ -z "$DB_SECRET" ] || [ "$DB_SECRET" == "null" ]; then
    fail "Could not find global DB secret in terraform.tfstate!"
  fi
  POSTGRES_USER=$(echo $DB_SECRET | jq -r '.username')
  POSTGRES_PASSWORD=$(echo $DB_SECRET | jq -r '.password')
  POSTGRES_DB="$POSTGRES_USER"
  # Remove existing container and volume for a fresh init
  if docker ps -a --format '{{.Names}}' | grep -q "^$POSTGRES_CONTAINER_NAME$"; then
    echo -e "${YELLOW}Removing existing Postgres container to reset credentials and schema...${NC}"
    docker rm -f $POSTGRES_CONTAINER_NAME || fail "Failed to remove existing Postgres container!"
    docker volume rm ${POSTGRES_CONTAINER_NAME}-data 2>/dev/null || true
  fi
  # Check if the container is already running
  if ! docker ps --format '{{.Names}}' | grep -q "^$POSTGRES_CONTAINER_NAME$"; then
    echo -e "${YELLOW}Starting local Postgres container for development...${NC}"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    docker run -d \
      --name $POSTGRES_CONTAINER_NAME \
      -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
      -e POSTGRES_USER=$POSTGRES_USER \
      -e POSTGRES_DB=$POSTGRES_DB \
      -p 5432:5432 \
      -v ${POSTGRES_CONTAINER_NAME}-data:/var/lib/postgresql/data \
      -v "$SCRIPT_DIR/server/sql/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
      postgres:15 || fail "Failed to start local Postgres container!"
    # Wait for Postgres to be ready
    echo -e "${YELLOW}Waiting for Postgres to be ready...${NC}"
    until docker exec $POSTGRES_CONTAINER_NAME pg_isready -U $POSTGRES_USER; do
      sleep 1
    done
    echo -e "${GREEN}Postgres is ready!${NC}"
  else
    echo -e "${GREEN}Postgres container already running.${NC}"
  fi
fi

# Move to infra directory and apply Terraform
cd ../infra || fail "Infra directory not found"
echo -e "${YELLOW}Applying Terraform changes to update ECS task definition and service...${NC}"
terraform apply -auto-approve || fail "Terraform apply failed!"
echo -e "${GREEN}Terraform apply completed successfully!${NC}" 