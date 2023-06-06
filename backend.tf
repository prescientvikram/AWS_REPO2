
terraform {
  backend "s3" {
    bucket = "mybucket-vikram"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}