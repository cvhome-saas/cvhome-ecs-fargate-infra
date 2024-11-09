provider "aws" {
  region = "eu-central-1"
}

locals {
  tags = {
    Project     = var.project
    Terraform   = "true"
    Environment = var.env
  }
}