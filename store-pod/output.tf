output "domain" {
  value = "store-pod-saas-gateway-${var.pod.index}.${var.domain_zone_name}"
}