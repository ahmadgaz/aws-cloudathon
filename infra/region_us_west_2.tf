resource "aws_cloudwatch_log_group" "ecs_backend_west" {
  provider = aws.us_west_2
  name              = "/ecs/simple-backend"
  retention_in_days = 7
}

module "network_us_west_2" {
  source              = "./modules/network"
  providers           = { aws = aws.us_west_2 }
  region              = "us-west-2"
  cidr_block          = "10.2.0.0/16"
  public_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24"]
  azs                 = ["us-west-2a", "us-west-2b"]
}

module "ecr_us_west_2" {
  source    = "./modules/ecr"
  providers = { aws = aws.us_west_2 }
  region    = "us-west-2"
}

resource "random_password" "db_password_us_west_2" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_secret_us_west_2" {
  provider = aws.us_west_2
  name = "us-west-2-db-secret-new-v3"
}

resource "aws_secretsmanager_secret_version" "db_secret_version_us_west_2" {
  provider = aws.us_west_2
  secret_id     = aws_secretsmanager_secret.db_secret_us_west_2.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password_us_west_2.result
  })
}

module "rds_us_west_2" {
  source                = "./modules/rds"
  providers             = { aws = aws.us_west_2 }
  region                = "us-west-2"
  db_subnet_ids         = module.network_us_west_2.public_subnet_ids
  db_security_group_ids = [module.network_us_west_2.db_security_group_id]
  engine                = "aurora-postgresql"
  engine_version        = "15.4"
  master_username       = "dbadmin"
  master_password       = random_password.db_password_us_west_2.result
  instance_count        = 1
  instance_class        = "db.t3.medium"
  engine_family         = "POSTGRESQL"
  # Ensure this role is in the same account and trusted for RDS Proxy
  proxy_role_arn        = "arn:aws:iam::037297136404:role/AdminRole"
  db_secret_arn         = aws_secretsmanager_secret.db_secret_us_west_2.arn
}

module "alb_us_west_2" {
  source                = "./modules/alb"
  providers             = { aws = aws.us_west_2 }
  region                = "us-west-2"
  public_subnet_ids     = module.network_us_west_2.public_subnet_ids
  alb_security_group_ids = [module.network_us_west_2.alb_security_group_id]
  vpc_id                = module.network_us_west_2.vpc_id
}

module "ecs_us_west_2" {
  source                = "./modules/ecs"
  providers             = { aws = aws.us_west_2 }
  region                = "us-west-2"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "arn:aws:iam::037297136404:role/AdminRole"
  task_role_arn         = "arn:aws:iam::037297136404:role/AdminRole"
  image_tag             = var.image_tag
  container_definitions = <<DEFINITION
[
  {
    "name": "backend",
    "image": "${module.ecr_us_west_2.repository_url}:${var.image_tag}",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      { "containerPort": 3000 }
    ],
    "environment": [
      { "name": "DATABASE_URL", "value": "postgresql+asyncpg://dbadmin:${random_password.db_password_us_west_2.result}@host.docker.internal:5432/postgres" },
      { "name": "NODE_ENV", "value": "production" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "us-west-2",
        "awslogs-group": "/ecs/simple-backend",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION

  # PRODUCTION (AWS):
  # Swap the DATABASE_URL line in the above JSON to:
  # { "name": "DATABASE_URL", "value": "postgresql+asyncpg://dbadmin:${random_password.db_password_us_west_2.result}@${module.rds_us_west_2.proxy_endpoint}:5432/postgres" },
  desired_count         = 1
  subnet_ids            = module.network_us_west_2.public_subnet_ids
  security_group_ids    = [module.network_us_west_2.security_group_id]
  target_group_arn      = module.alb_us_west_2.target_group_arn
  container_name        = "backend"
  container_port        = 3000
  lb_dependency         = module.alb_us_west_2.listener
}

module "waf_us_west_2" {
  source    = "./modules/waf"
  providers = { aws = aws.us_west_2 }
  region    = "us-west-2"
  alb_arn   = module.alb_us_west_2.alb_arn
} 