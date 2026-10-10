
# Application Load Balancer
resource "aws_lb" "boardgame_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

# Target Group for Boardgame Application
resource "aws_lb_target_group" "boardgame_tg" {
  name        = "${var.project_name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.boardgame_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "8080"
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name    = "${var.project_name}-tg"
    Project = var.project_name
  }
}

# Temporary HTTP Listener for Testing
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.boardgame_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.boardgame_tg.arn
  }
}
