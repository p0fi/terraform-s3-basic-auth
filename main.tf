# #--------------------------------------------------------------
# // MARK: S3 Bucket
# #--------------------------------------------------------------
# resource "aws_s3_bucket" "default" {
#   bucket = var.bucket_name
#   acl    = "private"
#   tags   = var.tags
#   region = var.aws_region
# }

# data "aws_iam_policy_document" "s3_bucket_policy" {
#   statement {
#     actions = [
#       "s3:GetObject"
#     ]

#     resources = [
#       "${aws_s3_bucket.default.arn}/*",
#     ]

#     principals {
#       type = "AWS"
#       identifiers = [
#         aws_cloudfront_origin_access_identity.default.iam_arn,
#       ]
#     }
#   }

#   statement {
#     actions = [
#       "s3:ListBucket",
#     ]

#     resources = [
#       aws_s3_bucket.default.arn,
#     ]

#     principals {
#       type = "AWS"
#       identifiers = [
#         aws_cloudfront_origin_access_identity.default.iam_arn,
#       ]
#     }
#   }

#   statement {
#     actions = [
#       "s3:GetBucketLocation",
#       "s3:ListBucket"
#     ]

#     resources = [
#       aws_s3_bucket.default.arn,
#     ]

#     principals {
#       type        = "AWS"
#       identifiers = var.bucket_access_roles_arn_list
#     }
#   }

#   statement {
#     actions = [
#       "s3:GetObject",
#       "s3:PutObject"
#     ]

#     resources = [
#       "${aws_s3_bucket.default.arn}/*",
#     ]

#     principals {
#       type        = "AWS"
#       identifiers = var.bucket_access_roles_arn_list
#     }
#   }
# }

# resource "aws_s3_bucket_policy" "bucket_policy" {
#   bucket = aws_s3_bucket.default.id
#   policy = data.aws_iam_policy_document.s3_bucket_policy.json
# }

# #--------------------------------------------------------------
# // MARK: CF Distribution
# #--------------------------------------------------------------
# resource "aws_cloudfront_origin_access_identity" "default" {
#   comment = var.bucket_name
# }

# resource "aws_cloudfront_distribution" "default" {
#   origin {
#     domain_name = aws_s3_bucket.default.bucket_regional_domain_name
#     origin_id   = local.s3_origin_id

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
#     }
#   }

#   aliases             = concat([var.cloudfront_distribution], [var.bucket_name], var.cloudfront_aliases)
#   comment             = "Managed by Terraform"
#   default_root_object = var.cloudfront_default_root_object
#   enabled             = true
#   http_version        = "http2"
#   is_ipv6_enabled     = true
#   price_class         = var.cloudfront_price_class
#   tags                = var.tags

#   default_cache_behavior {
#     target_origin_id = local.s3_origin_id

#     // Read only
#     allowed_methods = [
#       "GET",
#       "HEAD",
#     ]

#     cached_methods = [
#       "GET",
#       "HEAD",
#     ]

#     forwarded_values {
#       query_string = true
#       headers = [
#         "Access-Control-Request-Headers",
#         "Access-Control-Request-Method",
#         "Origin",
#       ]

#       cookies {
#         forward = "none"
#       }
#     }

#     lambda_function_association {
#       event_type = "viewer-request"
#       lambda_arn = aws_lambda_function.default.qualified_arn
#     }

#     viewer_protocol_policy = "redirect-to-https"
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = (var.geo_restriction_whitelisted_locations == "") ? "none" : "whitelist"
#       locations        = (var.geo_restriction_whitelisted_locations == "") ? [] : [var.geo_restriction_whitelisted_locations]
#     }
#   }

#   viewer_certificate {
#     acm_certificate_arn            = var.cloudfront_acm_certificate_arn
#     ssl_support_method             = "sni-only"
#     cloudfront_default_certificate = false
#   }
# }

#--------------------------------------------------------------
// MARK: Lambda Function
#--------------------------------------------------------------
data "archive_file" "default" {
  type        = "zip"
  source_file = "${path.module}/index.js"
  output_path = "${path.root}/artifacts/index.zip"
}
# data "aws_iam_policy_document" "lambda_log_access" {
#   // Allow lambda access to logging
#   statement {
#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#     ]

#     resources = [
#       "arn:aws:logs:*:*:*",
#     ]

#     effect = "Allow"
#   }
# }

# # This function is created in us-east-1 as required by CloudFront.
# resource "aws_lambda_function" "default" {
#   depends_on = [null_resource.copy_lambda_artifact]

#   provider         = aws.us-east-1
#   description      = "Managed by Terraform"
#   runtime          = "nodejs10.x"
#   role             = aws_iam_role.lambda_role.arn
#   filename         = local.lambda_filename
#   function_name    = "cloudfront_auth"
#   handler          = "index.handler"
#   publish          = true
#   timeout          = 5
#   source_code_hash = filebase64sha256(data.null_data_source.lambda_artifact_sync.outputs["file"])
#   tags             = var.tags
# }

# resource "aws_iam_role" "default" {
#   name = "${var.resource-name-prefix}-${var.environment-tag}-iam-role"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "",
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# POLICY

#   tags = var.tags
# }

# # Attach the logging access document to the above role.
# resource "aws_iam_role_policy_attachment" "lambda_log_access" {
#   role       = aws_iam_role.default.name
#   policy_arn = aws_iam_policy.lambda_log_access.arn
# }

# # Create an IAM policy that will be attached to the role
# resource "aws_iam_policy" "lambda_log_access" {
#   name   = "cloudfront_auth_lambda_log_access"
#   policy = data.aws_iam_policy_document.lambda_log_access.json
# }

