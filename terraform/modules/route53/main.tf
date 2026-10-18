resource "aws_route53_record" "app" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# SSH ke liye naam: app-01.<zone>, app-02.<zone> -> PRIVATE IP.
# Private IP hone se ye naam sirf VPN (Pritunl) connected hone par kaam karta hai; baaki ke liye unreachable.
resource "aws_route53_record" "ssh" {
  count = length(var.server_private_ips)

  zone_id = var.zone_id
  name    = "app-${format("%02d", count.index + 1)}.${var.zone_name}"
  type    = "A"
  ttl     = 60
  records = [var.server_private_ips[count.index]]
}
