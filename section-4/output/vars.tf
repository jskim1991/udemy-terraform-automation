variable "AWS_ACCESS_KEY" {

}

variable "AWS_SECRET_KEY" {

}

variable "AWS_SESSION_TOKEN" {

}

variable "AWS_REGION" {
  default = "ap-northeast-1"
}

variable "AMIS" {
  type = map(string)
  default = {
    ap-northeast-1 = "ami-0822295a729d2a28e"
  }
}