resource "aws_s3_bucket" "example" {
  bucket = "my-demo-bucket-2023523"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}