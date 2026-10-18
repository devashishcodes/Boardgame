output "fqdn" {
  value = aws_route53_record.app.fqdn
}

output "ssh_hostnames" {
  value = aws_route53_record.ssh[*].fqdn
}
