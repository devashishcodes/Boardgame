variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name (resource names ka prefix)"
  type        = string
}

variable "environment" {
  description = "production ya staging (EC2 tag, deploy isi se servers dhundta hai)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for Boardgame VPC"
  type        = string
}

variable "public_subnet_az1_cidr" {
  description = "Public subnet CIDR for AZ1"
  type        = string
}

variable "public_subnet_az2_cidr" {
  description = "Public subnet CIDR for AZ2"
  type        = string
}

variable "private_subnet_az1_cidr" {
  description = "Private subnet CIDR for AZ1"
  type        = string
}

variable "private_subnet_az2_cidr" {
  description = "Private subnet CIDR for AZ2"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH PUBLIC key (ssh-ed25519 ...). Private key GitHub secret EC2_SSH_PRIVATE_KEY me jayegi"
  type        = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "domain_name" {
  description = "App ka FQDN, e.g. boardgame.example.com. Khali = domain/HTTPS abhi nahi (ALB DNS par HTTP)"
  type        = string
  default     = ""
}

variable "hosted_zone_name" {
  description = "Route53 public hosted zone, e.g. example.com. Khali = domain abhi nahi"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "SSH allow CIDRs. Empty = default VPC CIDR (jaha Pritunl hai)"
  type        = list(string)
  default     = []
}
