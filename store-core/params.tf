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
variable "tags" {
  type = map(string)
}
variable "log_s3_bucket_id" {
  type = string
}
variable "domain" {
  type = string
}
variable "certificate_arn" {
  type = string
}