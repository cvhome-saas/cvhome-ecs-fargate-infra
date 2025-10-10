data "aws_availability_zones" "available" {}
locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project}-${var.env}"
  cidr = local.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group = false

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = local.tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = merge(local.tags, {
    Name = "${var.project}-${var.env}-s3-endpoint"
  })
}


resource "aws_security_group" "vpce" {
  name        = "${var.project}-${var.env}-vpce-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr] # allow HTTPS from inside the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# ---------------------------------------------------------
# 🧩 Interface Endpoints (ECS, ECR, CloudWatch, STS, ServiceDiscovery)
# ---------------------------------------------------------
locals {
  interface_endpoints = {
    ecr_dkr          = "com.amazonaws.${var.region}.ecr.dkr"
    sts              = "com.amazonaws.${var.region}.sts"
    ecr_api          = "com.amazonaws.${var.region}.ecr.api"
    logs             = "com.amazonaws.${var.region}.logs"
    servicediscovery = "com.amazonaws.${var.region}.servicediscovery"
    data_servicediscovery = "com.amazonaws.${var.region}.data-servicediscovery"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = module.vpc.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project}-${var.env}-${each.key}-endpoint"
  })
}