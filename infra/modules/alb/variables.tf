variable "region" {
  description = "AWS region for ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_ids" {
  description = "List of security group IDs for ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for ALB"
  type        = string
} 