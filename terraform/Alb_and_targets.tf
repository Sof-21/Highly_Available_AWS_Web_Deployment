# Target group for ALB
resource "aws_lb_target_group" "web_server_tg" {
  name     = "web-server-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ha_vpc.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "web_server_tg"
  }
}


# Register EC2 #1
resource "aws_lb_target_group_attachment" "web_server_a" {
  target_group_arn = aws_lb_target_group.web_server_tg.arn
  target_id        = aws_instance.web_server_a.id
  port             = 80
}

# Register EC2 #2
resource "aws_lb_target_group_attachment" "web_server_b" {
  target_group_arn = aws_lb_target_group.web_server_tg.arn
  target_id        = aws_instance.web_server_b.id
  port             = 80
}





# ALB Creation
resource "aws_lb" "ha_lb" {
  name               = "ha-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "ha_alb"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ha_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_tg.arn
  }
} 