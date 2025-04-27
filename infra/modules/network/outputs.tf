output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_ids" {
  value = [aws_vpc.main.id]
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "public_subnet_ids_2" {
  value = slice(aws_subnet.public[*].id, 0, 2)
}

output "internet_gateway_id" {
  value = aws_internet_gateway.gw.id
}

output "internet_gateway_ids" {
  value = [aws_internet_gateway.gw.id]
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "security_group_ids" {
  value = [aws_security_group.main.id]
}

output "subnet_ids_2" {
  value = slice(aws_subnet.public[*].id, 0, 2)
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "azs" {
  value = var.azs
}

output "region" {
  value = var.region
}

output "all_security_group_ids" {
  value = [aws_security_group.main.id]
}

output "public_subnet_id" {
  value = aws_subnet.public[0].id
}

output "first_security_group_id" {
  value = aws_security_group.main.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
} 