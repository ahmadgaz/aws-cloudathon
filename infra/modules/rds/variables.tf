variable "region" {
  description = "AWS region for RDS resources"
  type        = string
}

variable "db_subnet_ids" {
  description = "List of subnet IDs for RDS"
  type        = list(string)
}

variable "db_security_group_ids" {
  description = "List of security group IDs for RDS"
  type        = list(string)
}

variable "engine" {
  description = "Database engine (e.g., aurora-postgresql)"
  type        = string
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "instance_count" {
  description = "Number of RDS cluster instances"
  type        = number
}

variable "instance_class" {
  description = "Instance class for RDS cluster instances"
  type        = string
}

variable "engine_family" {
  description = "Engine family for RDS Proxy (e.g., POSTGRESQL)"
  type        = string
}

variable "proxy_role_arn" {
  description = "IAM role ARN for RDS Proxy"
  type        = string
}

variable "db_secret_arn" {
  description = "Secret ARN for RDS Proxy authentication"
  type        = string
} 