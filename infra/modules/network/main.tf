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

resource "aws_security_group" "main" {
  provider    = aws
  name        = "${var.region}-main-sg"
  description = "Main security group for demo"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.region}-main-sg" }
} 