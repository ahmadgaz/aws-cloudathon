variable "region" {
  description = "AWS region for ECS resources"
  type        = string
}

variable "cpu" {
  description = "CPU units for the ECS task"
  type        = string
}

variable "memory" {
  description = "Memory for the ECS task"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM execution role ARN for ECS task"
  type        = string
}

variable "task_role_arn" {
  description = "IAM task role ARN for ECS task"
  type        = string
}

variable "container_definitions" {
  description = "Container definitions JSON for ECS task"
  type        = string
}

variable "desired_count" {
  description = "Desired number of ECS service tasks"
  type        = number
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for ECS service"
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group ARN for ECS service"
  type        = string
}

variable "container_name" {
  description = "Container name for load balancer"
  type        = string
}

variable "container_port" {
  description = "Container port for load balancer"
  type        = number
}

variable "lb_dependency" {
  description = "Dependency for load balancer creation"
  type        = any
}

variable "image_tag" {
  description = "Docker image tag for ECS"
  type        = string
} 