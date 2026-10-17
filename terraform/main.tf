data "aws_availability_zones" "available" {
  state = "available"
}

# ---- default VPC (yahi Pritunl VPN server hai) ----
data "aws_vpc" "default" {
  default = true
}

data "aws_route_tables" "default" {
  vpc_id = data.aws_vpc.default.id
}

locals {
  azs               = slice(data.aws_availability_zones.available.names, 0, 2)
  ssh_allowed_cidrs = length(var.ssh_allowed_cidrs) > 0 ? var.ssh_allowed_cidrs : [data.aws_vpc.default.cidr_block]

  # Domain optional: domain_name + hosted_zone_name dono bharo to HTTPS + Route53 ban jayenge
  enable_domain = var.domain_name != "" && var.hosted_zone_name != ""
}

data "aws_route53_zone" "this" {
  count = local.enable_domain ? 1 : 0

  name         = var.hosted_zone_name
  private_zone = false
}

# ---- Network: VPC, 2 public + 2 private subnets, IGW, 1 NAT, route tables ----
module "vpc" {
  source = "./modules/vpc"

  name_prefix          = var.project_name
  vpc_cidr             = var.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = [var.public_subnet_az1_cidr, var.public_subnet_az2_cidr]
  private_subnet_cidrs = [var.private_subnet_az1_cidr, var.private_subnet_az2_cidr]
}

# ---- VPC peering: default-vpc (Pritunl) <-> boardgame-vpc ----
module "vpc_peering" {
  source = "./modules/vpc_peering"

  name_prefix   = var.project_name
  vpc_id        = module.vpc.vpc_id
  vpc_cidr      = module.vpc.vpc_cidr
  peer_vpc_id   = data.aws_vpc.default.id
  peer_vpc_cidr = data.aws_vpc.default.cidr_block

  local_route_table_ids = [
    module.vpc.public_route_table_id,
    module.vpc.private_route_table_id,
  ]
  peer_route_table_ids = data.aws_route_tables.default.ids
}

module "security_groups" {
  source = "./modules/security_groups"

  name_prefix       = var.project_name
  vpc_id            = module.vpc.vpc_id
  app_port          = var.app_port
  ssh_allowed_cidrs = local.ssh_allowed_cidrs
}

# ---- App servers (private subnets, 1 per AZ) ----
module "ec2" {
  source = "./modules/ec2"

  name_prefix        = var.project_name
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.app_sg_id]
  instance_type      = var.instance_type
  ssh_public_key     = var.ssh_public_key
}

# ---- TLS certificate (ACM, DNS validation) - sirf domain ke saath ----
module "acm" {
  source = "./modules/acm"
  count  = local.enable_domain ? 1 : 0

  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.this[0].zone_id
}

# ---- ALB + target group (public subnets) ----
module "alb" {
  source = "./modules/alb"

  name_prefix       = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
  enable_https      = local.enable_domain
  certificate_arn   = local.enable_domain ? module.acm[0].certificate_arn : ""
  instance_ids      = module.ec2.instance_ids
  app_port          = var.app_port
  health_check_path = var.health_check_path
}

# ---- Domain -> ALB (sirf domain ke saath) ----
module "route53" {
  source = "./modules/route53"
  count  = local.enable_domain ? 1 : 0

  zone_id      = data.aws_route53_zone.this[0].zone_id
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}
