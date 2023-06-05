data "aws_ip_ranges" "ap_northeast_1_ec2" {
  regions  = ["ap-northeast-1"]
  services = ["ec2"]
}

resource "aws_security_group" "from_ap_northeast_1" {
  name = "from_ap_northeast_1"

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = slice(data.aws_ip_ranges.ap_northeast_1_ec2.cidr_blocks, 0, 50)
  }
  tags = {
    CreateDate = data.aws_ip_ranges.ap_northeast_1_ec2.create_date
    SyncToken  = data.aws_ip_ranges.ap_northeast_1_ec2.sync_token
  }
}

