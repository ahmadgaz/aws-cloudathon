resource "aws_db_subnet_group" "main" {
  name       = "${var.region}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags = { Name = "${var.region}-db-subnet-group" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.region}-db-cluster"
  engine                 = var.engine
  engine_version         = var.engine_version
  master_username        = var.master_username
  master_password        = var.master_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.db_security_group_ids
  skip_final_snapshot    = true
  tags = { Name = "${var.region}-db-cluster" }

  depends_on = [aws_db_subnet_group.main]

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_rds_cluster_instance" "main" {
  count              = var.instance_count
  identifier         = "${var.region}-db-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version
  publicly_accessible = false
  tags = { Name = "${var.region}-db-instance-${count.index}" }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_db_proxy" "main" {
  name                   = "${var.region}-db-proxy"
  engine_family          = var.engine_family
  role_arn               = var.proxy_role_arn
  vpc_subnet_ids         = var.db_subnet_ids
  vpc_security_group_ids = var.db_security_group_ids
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.db_secret_arn
  }
  tags = { Name = "${var.region}-db-proxy" }

  depends_on = [aws_rds_cluster.main]
} 