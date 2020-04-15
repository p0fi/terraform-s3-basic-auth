provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

#--------------------------------------------------------------
// MARK: S3 Bucket
#--------------------------------------------------------------
resource "aws_s3_bucket" "default" {
  region = var.aws_region
  bucket = var.bucket_name
  acl    = "private"

  tags = var.tags

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.default.id}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
}
POLICY
}

locals {
  s3_origin_id = "S3-${var.bucket_name}"
}

# #--------------------------------------------------------------
# // MARK: CF Distribution
# #--------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "default" {
  comment = var.bucket_name
}

resource "aws_cloudfront_distribution" "default" {
  origin {
    domain_name = aws_s3_bucket.default.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  # aliases             = concat([var.cloudfront_distribution], [var.bucket_name], var.cloudfront_aliases)
  comment             = "Managed by Terraform"
  default_root_object = var.cloudfront_default_root_object
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  tags                = var.tags

  default_cache_behavior {
    target_origin_id = local.s3_origin_id

    // Read only
    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    forwarded_values {
      query_string = true
      headers = [
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "Origin",
      ]

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.default.qualified_arn
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    #acm_certificate_arn            = var.cloudfront_acm_certificate_arn
    #ssl_support_method             = "sni-only"
    cloudfront_default_certificate = true
  }
}

#--------------------------------------------------------------
// MARK: Lambda Function
#--------------------------------------------------------------
resource "local_file" "default" {
  content = templatefile("${path.module}/index_template.js", {
    USER = var.user_name
    PASS = var.password
  })
  filename = "${path.module}/.archive/index.js"
}

data "archive_file" "default" {
  type        = "zip"
  source_file = "${path.module}/.archive/index.js"
  output_path = "${path.module}/.archive/index.zip"

  depends_on = [
    local_file.default
  ]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "basic-auth-lambda"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com",
                    "edgelambda.amazonaws.com"
                ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
POLICY

  tags = var.tags
}

resource "aws_lambda_function" "default" {
  # This function is created in us-east-1 as required by CloudFront.
  provider      = aws.us_east_1
  function_name = "cloudfront-basic-auth"
  filename      = data.archive_file.default.output_path
  handler       = "index.handler"
  role          = aws_iam_role.iam_for_lambda.arn
  description   = "Lambda@Edge for Basic Auth with a CF Distribution"
  memory_size   = 128
  runtime       = "nodejs12.x"
  timeout       = 5
  publish       = true
  #source_code_hash = filebase64sha256(data.archive_file.default.output_path)

  tags = var.tags
}
