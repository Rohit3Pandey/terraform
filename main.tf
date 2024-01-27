resource "aws_s3_bucket" "myBucket" {
  bucket = var.bucketname
}

resource "aws_s3_bucket_ownership_controls" "owner" {
  bucket = aws_s3_bucket.myBucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = "terraform-project-s3-2024"

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "Public-ACL" {
  depends_on = [
    aws_s3_bucket_ownership_controls.owner,
    aws_s3_bucket_public_access_block.public,
  ]

  bucket = aws_s3_bucket.myBucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.myBucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
  depends_on = [ aws_s3_bucket_acl.Public-ACL ]

}

resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.myBucket.id
    key = "index.html"
    source = "index.html"
    acl = "public-read"
    content_type = "text/html"
  
}

resource "aws_s3_object" "error" {
    bucket = aws_s3_bucket.myBucket.id
    key = "error.html"
    source = "error.html"
    acl = "public-read"
    content_type = "text/html"
  
}
