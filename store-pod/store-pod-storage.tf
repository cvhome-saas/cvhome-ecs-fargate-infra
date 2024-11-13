module "cdn-storage-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "${var.project}-${local.module_name}-${var.env}-cdn-storage-"


  force_destroy = true
  tags          = var.tags
}
