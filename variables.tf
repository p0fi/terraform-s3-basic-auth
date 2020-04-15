# variable "cloudfront_distribution" {
#   type        = string
#   description = "The cloudfront distribtion"
# }

# variable "redirect_uri" {
#   type        = string
#   description = "The redirect uri "
# }

# variable "session_duration" {
#   type        = string
#   default     = "1"
#   description = "Session duration in hours"
# }

variable "user_name" {
  type        = string
  description = "The user name for the basic auth"
}

variable "password" {
  type        = string
  description = "The password for the basic auth"
}

variable "bucket_name" {
  type        = string
  description = "The name of your s3 bucket"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to label resources with (e.g map('dev', 'prod'))"
}

variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "The region to deploy the S3 bucket into"
}

# variable "cloudfront_aliases" {
#   type        = list(string)
#   default     = []
#   description = "List of FQDNs to be used as alternative domain names (CNAMES) for Cloudfront"
# }

variable "cloudfront_price_class" {
  type        = string
  default     = "PriceClass_All"
  description = "Cloudfront price classes: `PriceClass_All`, `PriceClass_200`, `PriceClass_100`"
}

variable "cloudfront_default_root_object" {
  type        = string
  default     = "index.html"
  description = "The default root object of the Cloudfront distribution"
}

# variable "cloudfront_acm_certificate_arn" {
#   description = "ACM Certificate ARN for Cloudfront"
#   default     = ""
# }

# variable "nodejs_version" {
#   type        = string
#   default     = "nodejs12.x"
#   description = "Node.js runtime version."
# }

# variable "bucket_access_roles_arn_list" {
#   type        = list(string)
#   description = "A Role ARN which granted RW rights to bucket (to be used by instance profiles)"
# }