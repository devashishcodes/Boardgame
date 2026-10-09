variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
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
