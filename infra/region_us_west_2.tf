module "network_us_west_2" {
  source              = "./modules/network"
  region              = "us-west-2"
  cidr_block          = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  azs                 = ["us-west-2a", "us-west-2b"]
}

module "ecr_us_west_2" {
  source = "./modules/ecr"
  region = "us-west-2"
}

module "rds_us_west_2" {
  source                = "./modules/rds"
  region                = "us-west-2"
  db_subnet_ids         = ["subnet-23456789", "subnet-98765432"]
  db_security_group_ids = ["sg-23456789"]
  engine                = "aurora-postgresql"
  engine_version        = "13.6"
  master_username       = "admin"
  master_password       = "password1234"
  instance_count        = 1
  instance_class        = "db.t3.medium"
  engine_family         = "POSTGRESQL"
  proxy_role_arn        = "arn:aws:iam::123456789012:role/demo-rds-proxy-role"
  db_secret_arn         = "arn:aws:secretsmanager:us-west-2:123456789012:secret:demo-db-secret"
}

module "ecs_us_west_2" {
  source                = "./modules/ecs"
  region                = "us-west-2"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "arn:aws:iam::123456789012:role/demo-ecs-exec-role"
  task_role_arn         = "arn:aws:iam::123456789012:role/demo-ecs-task-role"
  container_definitions = "[]"
  desired_count         = 1
  subnet_ids            = ["subnet-23456789", "subnet-98765432"]
  security_group_ids    = ["sg-23456789"]
  target_group_arn      = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/demo-tg/abcdef123456"
  container_name        = "demo-container"
  container_port        = 80
  lb_dependency         = null
}

module "alb_us_west_2" {
  source                = "./modules/alb"
  region                = "us-west-2"
  public_subnet_ids     = ["subnet-23456789", "subnet-98765432"]
  alb_security_group_ids = ["sg-23456789"]
  vpc_id                = module.network_us_west_2.vpc_id
}

module "waf_us_west_2" {
  source   = "./modules/waf"
  region   = "us-west-2"
  alb_arn  = module.alb_us_west_2.alb_arn
} 