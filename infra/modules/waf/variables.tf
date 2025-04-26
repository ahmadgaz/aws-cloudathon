variable "region" {
  description = "AWS region for WAF"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with WAF"
  type        = string
} 