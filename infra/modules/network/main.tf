resource "aws_vpc" "main" {
  provider   = aws
  cidr_block = var.cidr_block
  tags = { Name = "${var.region}-vpc" }
}

resource "aws_subnet" "public" {
  provider          = aws
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "${var.region}-public-${count.index}" }
}

resource "aws_internet_gateway" "gw" {
  provider = aws
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.region}-igw" }
}

resource "aws_security_group" "alb" {
  provider    = aws
  name        = "${var.region}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere (or restrict as needed)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.region}-alb-sg" }
}

resource "aws_security_group" "main" {
  provider    = aws
  name        = "${var.region}-main-sg"
  description = "Main security group for demo"
  vpc_id      = aws_vpc.main.id

  # Allow inbound Postgres from within the VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # Allow inbound app traffic from ALB security group (to port 3000)
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Outbound open (default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.region}-main-sg" }
}

resource "aws_security_group" "db" {
  provider    = aws
  name        = "${var.region}-db-sg"
  description = "Security group for RDS/Proxy"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.main.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.region}-db-sg" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.region}-public-rt" }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

