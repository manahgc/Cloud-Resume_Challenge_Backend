variable "aws_region" {
    description = "Aws Region"
    type = string
}

variable "accountId" {
    description = "Account ID"
    type = string
}

variable "bucket_name" {
    description = "Name of Website Bucket"
    type = string  
}

variable "access_log_bucket_name" {
    description = "Name of access_log bucket"
    type = string
  
}

variable "domain_name" {
    description = "Registered domain name"
    type = string
}

variable "s3_origin_id" {
    description = "s3 website endpoint"
    type = string
  
}

variable "sender_email" {
    description = "sender email"
    type = string
  
}

variable "receiving_email" {
    description = "receiving email"
    type = string
  
}