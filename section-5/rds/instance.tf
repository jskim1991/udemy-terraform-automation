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


variable "RDS_PASSWORD" {
  type = string
  default = "a1c9f8v0zs"
}

provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  token      = var.AWS_SESSION_TOKEN
  region     = var.AWS_REGION
}


resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

resource "aws_instance" "example" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"

  # the VPC subnet
  subnet_id = aws_subnet.demo_vpc-public-1.id

  # the security group
  vpc_security_group_ids = [aws_security_group.example-instance.id]

  # the public SSH key
  key_name = aws_key_pair.mykeypair.key_name
}


# Internet VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "demo_vpc"
  }
}

# Subnets
resource "aws_subnet" "demo_vpc-public-1" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "demo_vpc-public-1"
  }
}

resource "aws_subnet" "demo_vpc-public-2" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-northeast-2c"

  tags = {
    Name = "demo_vpc-public-2"
  }
}

resource "aws_subnet" "demo_vpc-private-1" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "demo_vpc-private-1"
  }
}

resource "aws_subnet" "demo_vpc-private-2" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-northeast-2c"

  tags = {
    Name = "demo_vpc-private-2"
  }
}

# Internet GW
resource "aws_internet_gateway" "demo_vpc-gw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_vpc"
  }
}

# route tables
resource "aws_route_table" "demo_vpc-public" {
  vpc_id = aws_vpc.demo_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_vpc-gw.id
  }

  tags = {
    Name = "demo_vpc-public-1"
  }
}

# route associations public
resource "aws_route_table_association" "demo_vpc-public-1-a" {
  subnet_id      = aws_subnet.demo_vpc-public-1.id
  route_table_id = aws_route_table.demo_vpc-public.id
}
resource "aws_route_table_association" "demo_vpc-public-2-a" {
  subnet_id      = aws_subnet.demo_vpc-public-2.id
  route_table_id = aws_route_table.demo_vpc-public.id
}






// 1. subnet group
resource "aws_db_subnet_group" "mariadb-subnet" {
  name        = "mariadb-subnet"
  description = "RDS subnet group"
  subnet_ids  = [aws_subnet.demo_vpc-private-1.id, aws_subnet.demo_vpc-private-2.id]
}

// 2. parameter group
resource "aws_db_parameter_group" "mariadb-parameters" {
  name        = "mariadb-parameters"
  family      = "mariadb10.4"
  description = "MariaDB parameter group"

  parameter {
    name  = "max_allowed_packet"
    value = "16777216"
  }
}

// 3. security group
resource "aws_security_group" "example-instance" {
  vpc_id      = aws_vpc.demo_vpc.id
  name        = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "example-instance"
  }
}

resource "aws_security_group" "allow-mariadb" {
  vpc_id      = aws_vpc.demo_vpc.id
  name        = "allow-mariadb"
  description = "allow-mariadb"
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.example-instance.id] # allowing access from our example instance
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
  tags = {
    Name = "allow-mariadb"
  }
}

// 4. rds instance
resource "aws_db_instance" "mariadb" {
  allocated_storage       = 100 # 100 GB of storage, gives us more IOPS than a lower number
  engine                  = "mariadb"
  engine_version          = "10.4"
  instance_class          = "db.t2.micro" # use micro if you want to use the free tier
  identifier              = "mariadb"
  db_name                 = "mariadb"
  username                = "root"           # username
  password                = var.RDS_PASSWORD # password
  db_subnet_group_name    = aws_db_subnet_group.mariadb-subnet.name
  parameter_group_name    = aws_db_parameter_group.mariadb-parameters.name
  multi_az                = "false" # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids  = [aws_security_group.allow-mariadb.id]
  storage_type            = "gp2"
  backup_retention_period = 30                                          # how long you’re going to keep your backups
  availability_zone       = aws_subnet.demo_vpc-private-2.availability_zone # preferred AZ
  skip_final_snapshot     = true                                        # skip final snapshot when doing terraform destroy
  tags = {
    Name = "mariadb-instance"
  }
}

output "instance" {
  value = aws_instance.example.public_ip
}

output "rds" {
  value = aws_db_instance.mariadb.endpoint
}

terraform {
  required_version = ">= 0.12"
}
