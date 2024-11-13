resource "aws_service_discovery_private_dns_namespace" "cluster_namespace" {
  name = var.namespace
  vpc  = var.vpc_id
  tags = var.tags
}
