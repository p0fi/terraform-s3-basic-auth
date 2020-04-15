output "s3_bucket" {
  description = "The name of the S3 Bucket"
  value       = aws_s3_bucket.default.id
}

output "cloudfront_id" {
  description = "ID of the Cloudfront Distribution"
  value       = aws_cloudfront_distribution.default.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the Cloudfront Distribution"
  value       = aws_cloudfront_distribution.default.domain_name
}
