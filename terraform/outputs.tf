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
  value = local.enable_domain ? "https://${var.domain_name}" : "http://${module.alb.alb_dns_name}"
}

output "vpc_peering_id" {
  value = module.vpc_peering.peering_connection_id
}

output "ssh_hostnames" {
  description = "VPN connected hone par: ssh ec2-user@<hostname>"
  value       = local.enable_domain ? module.route53[0].ssh_hostnames : []
}
