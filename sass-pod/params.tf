variable "env" {
  type = string
}
variable "project" {
  type = string
}
variable "index" {
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
variable "domain_zone_id" {
  type = string
}
variable "certificate_arn" {
  type = string
}
