variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "enable_https" {
  description = "true = HTTPS listener + HTTP redirect (domain/ACM ke saath)"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN (enable_https = true ho tab)"
  type        = string
  default     = ""
}

variable "instance_ids" {
  type = list(string)
}

variable "app_port" {
  type = number
}

variable "health_check_path" {
  type = string
}
