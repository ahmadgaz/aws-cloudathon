output "alb_arn" {
  value = aws_lb.public.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "listener" {
  value = aws_lb_listener.http
} 