variable "env" {
  type = string
}
variable "project" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnets" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}
variable "database_subnets" {
  type = list(string)
}
variable "vpc_cidr_block" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "log_s3_bucket_id" {
  type = string
}
variable "domain" {
  type = string
}
variable "domain_zone_name" {
  type = string
}
variable "certificate_arn" {
  type = string
}
variable "db_instance_class" {
  default = "db.t4g.micro"
}
variable "db_allocated_storage" {
  default = 20
}
variable "docker_registry" {
  type = string
}
variable "image_version" {
  type = string
}
variable "namespace" {
  type = string
}
