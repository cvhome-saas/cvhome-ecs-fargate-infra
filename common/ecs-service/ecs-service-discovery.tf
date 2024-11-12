resource "aws_service_discovery_service" "this" {
  name = var.service_name
  dns_config {
    namespace_id = var.namespace_id
    dns_records {
      ttl  = 10
      type = "SRV"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  tags     = var.tags
}
