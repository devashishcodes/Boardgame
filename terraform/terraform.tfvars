# Production (default). Staging: envs/staging.tfvars
aws_region   = "ap-south-1"
project_name = "boardgame"
environment  = "production"

vpc_cidr = "10.0.0.0/16"

public_subnet_az1_cidr = "10.0.1.0/24"
public_subnet_az2_cidr = "10.0.2.0/24"

private_subnet_az1_cidr = "10.0.11.0/24"
private_subnet_az2_cidr = "10.0.12.0/24"

instance_type = "t3.micro"

# ssh-keygen -t ed25519 -f boardgame_deploy  ->  .pub ka content yaha, private key GitHub secret me
ssh_public_key = "CHANGE_ME ssh-ed25519 AAAA... deploy"

# Apna domain yaha daalo (Route53 public hosted zone pehle se honi chahiye)
domain_name      = "boardgame.CHANGE_ME.com"
hosted_zone_name = "CHANGE_ME.com"
