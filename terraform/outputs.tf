output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "app_private_ips" {
  value = module.ec2.private_ips
}

output "app_url" {
  value = "https://${var.domain_name}"
}

output "vpc_peering_id" {
  value = module.vpc_peering.peering_connection_id
}
