variable "AWS_REGION" {
  default = "ap-northeast-1"
}

variable "AMIS" {
  type = map(string)
  default = {
    ap-northeast-1 = "ami-0822295a729d2a28e"
  }
}