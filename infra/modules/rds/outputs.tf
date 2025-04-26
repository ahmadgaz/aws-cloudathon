output "proxy_endpoint" {
  description = "The endpoint of the RDS proxy"
  value       = aws_db_proxy.main.endpoint
}

output "db_cluster_endpoint" {
  description = "The endpoint of the RDS cluster"
  value       = aws_rds_cluster.main.endpoint
} 