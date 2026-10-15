variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  type = number
}

variable "ssh_allowed_cidrs" {
  type = list(string)
}
