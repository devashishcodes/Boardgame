terraform {
  backend "s3" {
    bucket       = "devashish-boardgame-terraform-state-2026"
    key          = "boardgame/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
