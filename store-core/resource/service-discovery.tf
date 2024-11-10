resource "aws_service_discovery_private_dns_namespace" "cluster-namespace" {
  name = var.cluster_dnsname
  vpc  = var.vpc_id
  tags = var.tags
}

resource "aws_service_discovery_service" "cluster-service" {
  name = each.key
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cluster-namespace.id
    dns_records {
      ttl  = 10
      type = "SRV"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  for_each = var.cluster_services
  tags     = var.tags
}
