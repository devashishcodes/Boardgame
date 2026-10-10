
# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Boardgame EC2 Instance AZ1
resource "aws_instance" "app_az1" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_az1.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  tags = {
    Name    = "${var.project_name}-app-az1"
    Project = var.project_name
  }
}

# Boardgame EC2 Instance AZ2
resource "aws_instance" "app_az2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_az2.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  tags = {
    Name    = "${var.project_name}-app-az2"
    Project = var.project_name
  }
}

# Register EC2 instances with the ALB target group
resource "aws_lb_target_group_attachment" "app_az1" {
  target_group_arn = aws_lb_target_group.boardgame_tg.arn
  target_id        = aws_instance.app_az1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "app_az2" {
  target_group_arn = aws_lb_target_group.boardgame_tg.arn
  target_id        = aws_instance.app_az2.id
  port             = 8080
}
