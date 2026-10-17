# Staging stack: alag state key, alag CIDR (default-vpc ke route tables me clash na ho)
aws_region   = "ap-south-1"
project_name = "boardgame-staging"
environment  = "staging"

vpc_cidr = "10.1.0.0/16"

public_subnet_az1_cidr = "10.1.1.0/24"
public_subnet_az2_cidr = "10.1.2.0/24"

private_subnet_az1_cidr = "10.1.11.0/24"
private_subnet_az2_cidr = "10.1.12.0/24"

instance_type = "t3.micro"

ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAp12hejkdGbhowBFZ7pE+YzctmrBaS7fNAm50oqcGPf devashish@AsusRog"

# Domain last me (production jaisa): uncomment karke daalo
# domain_name      = "staging-boardgame.yourdomain.com"
# hosted_zone_name = "yourdomain.com"
