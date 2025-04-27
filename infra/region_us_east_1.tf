resource "aws_cloudwatch_log_group" "ecs_backend" {
  provider = aws.us_east_1
  name              = "/ecs/simple-backend"
  retention_in_days = 7
}

module "network_us_east_1" {
  source              = "./modules/network"
  providers           = { aws = aws.us_east_1 }
  region              = "us-east-1"
  cidr_block          = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  azs                 = ["us-east-1a", "us-east-1b"]
}

module "ecr_us_east_1" {
  source    = "./modules/ecr"
  providers = { aws = aws.us_east_1 }
  region    = "us-east-1"
}

resource "random_password" "db_password_us_east_1" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_secret_us_east_1" {
  provider = aws.us_east_1
  name = "us-east-1-db-secret-new-v3"
}

resource "aws_secretsmanager_secret_version" "db_secret_version_us_east_1" {
  provider = aws.us_east_1
  secret_id     = aws_secretsmanager_secret.db_secret_us_east_1.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password_us_east_1.result
  })
}

module "rds_us_east_1" {
  source                = "./modules/rds"
  providers             = { aws = aws.us_east_1 }
  region                = "us-east-1"
  db_subnet_ids         = module.network_us_east_1.public_subnet_ids
  db_security_group_ids = [module.network_us_east_1.db_security_group_id]
  engine                = "aurora-postgresql"
  engine_version        = "15.4"
  master_username       = "dbadmin"
  master_password       = random_password.db_password_us_east_1.result
  instance_count        = 1
  instance_class        = "db.t3.medium"
  engine_family         = "POSTGRESQL"
  # Ensure this role is in the same account and trusted for RDS Proxy
  proxy_role_arn        = "arn:aws:iam::037297136404:role/AdminRole"
  db_secret_arn         = aws_secretsmanager_secret.db_secret_us_east_1.arn
}

module "alb_us_east_1" {
  source                = "./modules/alb"
  providers             = { aws = aws.us_east_1 }
  region                = "us-east-1"
  public_subnet_ids     = module.network_us_east_1.public_subnet_ids
  alb_security_group_ids = [module.network_us_east_1.alb_security_group_id]
  vpc_id                = module.network_us_east_1.vpc_id
}

module "ecs_us_east_1" {
  source                = "./modules/ecs"
  providers             = { aws = aws.us_east_1 }
  region                = "us-east-1"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "arn:aws:iam::037297136404:role/AdminRole"
  task_role_arn         = "arn:aws:iam::037297136404:role/AdminRole"
  image_tag             = var.image_tag
  # For local development (LocalStack): use a static hostname in DATABASE_URL
  # For production (AWS), swap the DATABASE_URL line below to use the RDS proxy endpoint
  # LOCAL DEV:
  container_definitions = <<DEFINITION
[
  {
    "name": "backend",
    "image": "${module.ecr_us_east_1.repository_url}:${var.image_tag}",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      { "containerPort": 3000 }
    ],
    "environment": [
      { "name": "DATABASE_URL", "value": "postgresql+asyncpg://dbadmin:${random_password.db_password_us_east_1.result}@host.docker.internal:5432/dbadmin" },
      { "name": "NODE_ENV", "value": "production" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "us-east-1",
        "awslogs-group": "/ecs/simple-backend",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION

  # PRODUCTION (AWS):
  # Swap the DATABASE_URL line in the above JSON to:
  # { "name": "DATABASE_URL", "value": "postgresql+asyncpg://dbadmin:${random_password.db_password_us_east_1.result}@${module.rds_us_east_1.proxy_endpoint}:5432/postgres" },
  desired_count         = 1
  subnet_ids            = module.network_us_east_1.public_subnet_ids
  security_group_ids    = [module.network_us_east_1.security_group_id]
  target_group_arn      = module.alb_us_east_1.target_group_arn
  container_name        = "backend"
  container_port        = 3000
  lb_dependency         = module.alb_us_east_1.listener
}

module "waf_us_east_1" {
  source    = "./modules/waf"
  providers = { aws = aws.us_east_1 }
  region    = "us-east-1"
  alb_arn   = module.alb_us_east_1.alb_arn
}

