resource "random_password" "db" {
  length  = 16
  special = false
}

# A real cloud resource that is easy to change behind the tool's back: edit a tag in the S3 console.
# LIVE: resource "aws_s3_bucket" "demo" — bucket_prefix "tf-state-refresh-", force_destroy = true, tags { demo = "tf-vs-pulumi", env = "dev" }

# LIVE: output "bucket"
