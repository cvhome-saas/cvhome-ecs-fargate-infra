provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  store_core_namespace = "store-core.${var.project}.lcl"
  domain = data.aws_route53_zone.domain_zone.name
  tags = {
    Project     = var.project
    Terraform   = "true"
    Environment = var.env
  }
  private_ecr_docker_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.project}"
  docker_registry             = var.docker_registry != "" ? var.docker_registry : local.private_ecr_docker_registry
  xpods = [
    {
      index : 0
      id : "1"
      name : "default",
      size : "large"
    },
  ]
  pods = {
    for value in local.xpods : lookup(value, "name") => {
      index : lookup(value, "index")
      id : lookup(value, "id")
      name : lookup(value, "name")
      org : try(lookup(value, "org"), "")
      endpoint : "https://store-pod-${lookup(value, "id")}.${local.domain}"
      namespace : "store-pod-${lookup(value, "id")}.${var.project}.lcl"
      size : try(lookup(value, "size"), "large"),
      endpointType : "EXTERNAL"
    }
  }
}

data "aws_route53_zone" "domain_zone" {
  zone_id = local.zone_id
}

data "aws_acm_certificate" "certificate" {
  domain = local.domain
  statuses = ["ISSUED"]
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
