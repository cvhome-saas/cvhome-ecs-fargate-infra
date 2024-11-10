output "service_discovery_service_arn" {
  value = aws_service_discovery_service.cluster-service
}
output "cluster-namespace" {
  value = aws_service_discovery_private_dns_namespace.cluster-namespace
}
output "db" {
  value = module.db
}
output "db_password" {
  value = jsondecode(data.aws_secretsmanager_secret_version.current-db-secret-version.secret_string)["password"]
}