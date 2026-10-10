terraform {
  backend "s3" {
    bucket       = "sof-terraform-projects-states"
    key          = "highly-available-web-deployment/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}


