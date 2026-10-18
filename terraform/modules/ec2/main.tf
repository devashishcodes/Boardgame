# Ubuntu 24.04 LTS (Canonical ka official AMI, SSM parameter se latest)
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# SSM access (SSH ke alawa fallback)
resource "aws_iam_role" "this" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.this.name
}

# SSH key pair (public key Terraform me, private key GitHub secret me)
resource "aws_key_pair" "this" {
  key_name   = "${var.name_prefix}-deploy-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "app" {
  count = length(var.subnet_ids)

  ami                         = data.aws_ssm_parameter.ubuntu.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[count.index]
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = false

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_tokens   = "required" # IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "${var.name_prefix}-app-0${count.index + 1}"
    Role = "app"
  }
}
