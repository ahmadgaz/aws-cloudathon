module "network_us_east_1" {
  source              = "./modules/network"
  region              = "us-east-1"
  cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  azs                 = ["us-east-1a", "us-east-1b"]
}

module "ecr_us_east_1" {
  source = "./modules/ecr"
  region = "us-east-1"
}

module "rds_us_east_1" {
  source                = "./modules/rds"
  region                = "us-east-1"
  db_subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  db_security_group_ids = ["sg-12345678"]
  engine                = "aurora-postgresql"
  engine_version        = "13.6"
  master_username       = "admin"
  master_password       = "password1234"
  instance_count        = 1
  instance_class        = "db.t3.medium"
  engine_family         = "POSTGRESQL"
  proxy_role_arn        = "arn:aws:iam::123456789012:role/demo-rds-proxy-role"
  db_secret_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:demo-db-secret"
}

module "ecs_us_east_1" {
  source                = "./modules/ecs"
  region                = "us-east-1"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "arn:aws:iam::123456789012:role/demo-ecs-exec-role"
  task_role_arn         = "arn:aws:iam::123456789012:role/demo-ecs-task-role"
  container_definitions = "[]"
  desired_count         = 1
  subnet_ids            = ["subnet-12345678", "subnet-87654321"]
  security_group_ids    = ["sg-12345678"]
  target_group_arn      = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/demo-tg/abcdef123456"
  container_name        = "demo-container"
  container_port        = 80
  lb_dependency         = null
}

module "alb_us_east_1" {
  source                = "./modules/alb"
  region                = "us-east-1"
  public_subnet_ids     = ["subnet-12345678", "subnet-87654321"]
  alb_security_group_ids = ["sg-12345678"]
  vpc_id                = module.network_us_east_1.vpc_id
}

module "waf_us_east_1" {
  source   = "./modules/waf"
  region   = "us-east-1"
  alb_arn  = module.alb_us_east_1.alb_arn
} 