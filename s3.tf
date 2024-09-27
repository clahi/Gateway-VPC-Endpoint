resource "aws_s3_bucket" "my_bucket" {
  # Please update this bucket name because s3 bucket names have to be unique.
  bucket = "enpoint-bucket-asdlfj234da"

}

# S# bucket ACL access 
resource "aws_s3_bucket_ownership_controls" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_policy     = false
  block_public_acls       = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "my_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.my_bucket,
    aws_s3_bucket_public_access_block.my_bucket
  ]

  bucket = aws_s3_bucket.my_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "my_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.my_bucket,
    aws_s3_bucket_public_access_block.my_bucket
  ]
  bucket = aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Access-to-specific-VPCE-only",
        "Principal" : "*"
        "Action" : [
          "s3:*"
        ],
        "Effect" : "Deny",
        "Resource" : [
          aws_s3_bucket.my_bucket.arn,
          "${aws_s3_bucket.my_bucket.arn}/*",
        ],
        "Condition": {
            "StringNotEquals": {
                "aws:sourceVpce": aws_vpc_endpoint.s3_endpoint.id
            }
        }
      }
    ]
  })
}

