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
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAp12hejkdGbhowBFZ7pE+YzctmrBaS7fNAm50oqcGPf devashish@AsusRog"

# Domain LAST me: neeche dono lines uncomment karke apna domain daalo -> HTTPS + Route53 ban jayenge.
# Tab tak khali raho, app ALB ke DNS par HTTP se chalegi.
# (Route53 public hosted zone pehle se honi chahiye)
domain_name      = "boardgame.devashish-gitaction.in"
hosted_zone_name = "devashish-gitaction.in"
