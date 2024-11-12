locals {
  module_name     = "saas-pod-${var.index}"
  cluster_dnsname = "${local.module_name}.${var.project}.lcl"
}
