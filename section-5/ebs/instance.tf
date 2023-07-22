resource "aws_instance" "example" {
  ami = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"

  key_name = aws_key_pair.mykeypair.key_name
}

resource "aws_ebs_volume" "ebs-volume-1" {
  availability_zone = "ap-northeast-2c"
  size = 20
  type = "gp2"
  tags = {
    Name = "extra volume data"
  }
}

resource "aws_volume_attachment" "ebs-volume-1-attachment" {
  device_name = "/dev/xvdh"
  volume_id   = aws_ebs_volume.ebs-volume-1.id
  instance_id = aws_instance.example.id
  stop_instance_before_detaching = true
}