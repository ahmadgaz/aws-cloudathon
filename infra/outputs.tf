// Define shared outputs here as needed 

output "alb_us_east_1_dns_name" {
  value = module.alb_us_east_1.alb_dns_name
  description = "The DNS name of the us-east-1 ALB."
}

output "alb_us_east_1_localstack_url" {
  value = "http://${module.alb_us_east_1.alb_dns_name}:4566"
  description = "The LocalStack ALB URL for us-east-1 (use as API base URL in frontend)."
} 