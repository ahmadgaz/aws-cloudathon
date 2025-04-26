module "s3_cloudfront" {
  source      = "./modules/s3_cloudfront"
  providers   = { aws = aws.us_east_1 }
  bucket_name = "demo-bucket-123456-oliver-202406"
  # Add required variables here
} 