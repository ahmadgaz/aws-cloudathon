resource "aws_ecr_repository" "app" {
  name = "${var.region}-app-repo"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Name = "${var.region}-app-repo" }
} 