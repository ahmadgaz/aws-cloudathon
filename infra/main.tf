module "s3_cloudfront" {
  source      = "./modules/s3_cloudfront"
  bucket_name = "demo-bucket-123456"
  # Add required variables here
} 