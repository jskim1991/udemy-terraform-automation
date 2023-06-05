terraform {
  backend "s3" {
    bucket = "jay-terraform-state-bucket"
    key    = "terraform/state"
    region = "ap-northeast-1"
  }
}
