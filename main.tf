provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "certificate" {
  domain   = local.domain
  statuses = ["ISSUED"]
}

locals {
  store_core_namespace = "store-core.${var.project}.lcl"
  tags = {
    Project     = var.project
    Terraform   = "true"
    Environment = var.env
  }
  private_ecr_docker_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  docker_registry             = var.docker_registry != "" ? var.docker_registry : local.private_ecr_docker_registry
  xxpods = {
    for value in local.xpods : lookup(value,"name" ) => {
      index : lookup(value, "index")
      id : lookup(value, "id")
      name : "store-pod-${lookup(value, "index")}"
      org : lookup(value, "org")
      endpoint :  "store-pod-${lookup(value, "id")}.${var.project}.lcl"
      size : lookup(value, "size")
    }
  }
  pods = {
    for key, value in var.pods : key => {
      index : lookup(value, "index")
      id : lookup(value, "id")
      name : "store-pod-${lookup(value, "index")}"
      org : lookup(value, "org")
      endpoint : lookup(value, "endpointType") == "EXTERNAL" ? lookup(value, "endpoint") : "store-pod-${lookup(value, "id")}.${var.project}.lcl"
      endpointType : lookup(value, "endpointType")
      size : lookup(value, "size")
    }
  }

}

data "aws_route53_zone" "domain_zone" {
  name = local.domain
}

module "store-core" {
  source                     = "./store-core"
  vpc_id                     = module.vpc.vpc_id
  public_subnets             = module.vpc.public_subnets
  private_subnets            = module.vpc.private_subnets
  log_s3_bucket_id           = module.log-bucket.s3_bucket_id
  domain                     = local.domain
  certificate_arn            = data.aws_acm_certificate.certificate.arn
  domain_zone_name           = data.aws_route53_zone.domain_zone.name
  project                    = var.project
  tags                       = local.tags
  database_subnets           = module.vpc.database_subnets
  vpc_cidr_block             = local.vpc_cidr
  env                        = var.env
  image_tag                  = var.image_tag
  namespace                  = local.store_core_namespace
  pods                       = local.pods
  stripe_key                 = local.stripeKey
  stripe_webhook_signing_key = local.stripeWebhockSigningKey
  docker_registry            = local.docker_registry
  kc_username                = local.kcUsername
  kc_password                = local.kcPassword
}

module "store-pod" {
  source               = "./store-pod"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnets
  private_subnets      = module.vpc.private_subnets
  log_s3_bucket_id     = module.log-bucket.s3_bucket_id
  domain               = local.domain
  certificate_arn      = data.aws_acm_certificate.certificate.arn
  store_core_namespace = local.store_core_namespace
  domain_zone_name     = data.aws_route53_zone.domain_zone.name
  project              = var.project
  tags                 = local.tags
  database_subnets     = module.vpc.database_subnets
  vpc_cidr_block       = local.vpc_cidr
  env                  = var.env
  docker_registry      = local.docker_registry
  image_tag            = var.image_tag
  test_stores          = each.key == "default"
  pod                  = each.value
  for_each             = local.pods
}
