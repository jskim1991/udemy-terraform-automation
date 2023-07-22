variable "AWS_ACCESS_KEY" {

}

variable "AWS_SECRET_KEY" {

}

variable "AWS_SESSION_TOKEN" {

}

variable "AWS_REGION" {
  default = "ap-northeast-2"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "~/.ssh/id_rsa.pub"
}

variable "AMIS" {
  type = map(string)
  default = {
    ap-northeast-2 = "ami-0dd97ebb907cf9366"
  }
}