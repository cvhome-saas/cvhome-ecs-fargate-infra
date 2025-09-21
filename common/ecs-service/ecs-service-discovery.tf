resource "aws_service_discovery_service" "this" {
  name = var.service_name
  dns_config {
    namespace_id = var.namespace_id
    dns_records {
      ttl  = 10
      type = "A"
      # type = "SRV" caddy not working for it now
    }
    routing_policy = "MULTIVALUE"
  }
  tags = var.tags
}
