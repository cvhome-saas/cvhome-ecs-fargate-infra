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
variable "image_tag" {
  type = string
}
variable "namespace" {
  type = string
}
variable "pods" {
  type = map(object({
    index : number
    id : string
    name : string
    org : string
    endpoint : string
    namespace : string
    endpointType : string
    size : string
  }))
}
variable "stripe_key" {
  type = string
}
variable "stripe_webhook_signing_key" {
  type = string
}
variable "kc_username" {
  type = string
}
variable "kc_password" {
  type = string
}


