// Define shared variables here as needed 

variable "ecs_execution_role_arn_us_east_1" {
  description = "ECS execution role ARN for us-east-1"
  type        = string
}

variable "ecs_task_role_arn_us_east_1" {
  description = "ECS task role ARN for us-east-1"
  type        = string
}

variable "ecs_execution_role_arn_us_west_2" {
  description = "ECS execution role ARN for us-west-2"
  type        = string
}

variable "ecs_task_role_arn_us_west_2" {
  description = "ECS task role ARN for us-west-2"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag for ECS"
  type        = string
} 