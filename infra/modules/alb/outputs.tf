output "alb_arn" {
  value = aws_lb.public.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "listener" {
  value = aws_lb_listener.http
}

output "alb_security_group_id" {
  value = var.alb_security_group_ids[0]
} 