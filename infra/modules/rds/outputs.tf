output "proxy_endpoint" {
  description = "The endpoint of the RDS proxy"
  value       = aws_db_proxy.main.endpoint
}

output "db_cluster_endpoint" {
  description = "The endpoint of the RDS cluster"
  value       = aws_rds_cluster.main.endpoint
}

output "db_secret_arn" {
  value = var.db_secret_arn
  description = "The ARN of the DB secret used for the cluster."
}

output "global_cluster_identifier" {
  value = var.global_cluster_identifier
  description = "The global cluster identifier used for the cluster."
}

output "master_password" {
  value = var.master_password
  description = "The master password for the cluster."
} 