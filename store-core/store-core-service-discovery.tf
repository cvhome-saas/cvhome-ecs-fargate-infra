resource "aws_service_discovery_private_dns_namespace" "cluster_namespace" {
  name = local.cluster_dnsname
  vpc  = var.vpc_id
  tags = var.tags
}
