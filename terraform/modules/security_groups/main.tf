# ---- ALB SG: internet se 80/443 ----
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name_prefix}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# ALB sirf app instances ko traffic bhej sakta hai (existing repo jaisa)
resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "Traffic to application instances"
}

# ---- App SG: 8080 sirf ALB se, 22 sirf Pritunl/default-vpc se ----
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "App EC2 security group"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name_prefix}-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "App port from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_pritunl" {
  count = length(var.ssh_allowed_cidrs)

  security_group_id = aws_security_group.app.id
  cidr_ipv4         = var.ssh_allowed_cidrs[count.index]
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH via Pritunl VPN"
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
