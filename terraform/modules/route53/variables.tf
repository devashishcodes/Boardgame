variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "zone_name" {
  description = "Hosted zone name, e.g. example.com"
  type        = string
}

variable "server_private_ips" {
  description = "App servers ke private IPs (SSH hostnames ke liye)"
  type        = list(string)
}
