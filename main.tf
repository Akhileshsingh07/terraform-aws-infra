variable "ami_value" {
    description = "this is ami id"
  
}

variable "instance_type_value" {
    description = "this is instatance id"
  
}

variable "cidr_block-vpc-1" {
    description = "this is cidr range of vpc-1"
  
}

variable "cidr_block-pub-subnet" {
    description = "this is cider range of pub-subnet "
  
}
variable "pub-subnet-availability_zone" {
    description = "this is public subnet availabilty zone"
  
}

variable "rt-pub1-cidr_block" {
    description = "this is cidr range of route table 1"
  
}

terraform {
  backend "s3" {
    bucket                  = "terraform-proj-1"
    key                     = "key/terraform.tfstate"
    region                  = "ap-south-1"
  }
}

provider "aws" {
    region = "ap-south-1"
  
}


resource "aws_vpc" "vpc-1" {
  cidr_block = var.cidr_block-vpc-1 

  tags = {
    Name = "vpc-1-terra"
  }
}

#public subnet configuration

resource "aws_subnet" "pub-subnet" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = var.cidr_block-pub-subnet
  availability_zone = var.pub-subnet-availability_zone

  tags = {
    Name = "pub-sub-1-terra"
  }
}

resource "aws_route_table" "rt-pub1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block = var.rt-pub1-cidr_block
    gateway_id = aws_internet_gateway.gw-1.id
  }

  tags = {
    Name = "rt-pub-terra-1"
  }
}


resource "aws_route_table_association" "rt-ass-1" {
  subnet_id      = aws_subnet.pub-subnet.id
  route_table_id = aws_route_table.rt-pub1.id
}


resource "aws_internet_gateway" "gw-1" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    Name = "ig-1-terra"
  }
}
resource "aws_security_group" "terra-sg-pub" {
  name        = "security group using Terraform"
  description = "security group using Terraform"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terra-sg-pub"
  }
}

resource "aws_instance" "ec2-1" {
    ami = var.ami_value
    instance_type = var.instance_type_value
    subnet_id = aws_subnet.pub-subnet.id
    associate_public_ip_address = "true"
    security_groups = [aws_security_group.terra-sg-pub.id]
    
    tags = {
      Name = "ec2-terra-1"
    }
}

#private subnet configuration

resource "aws_subnet" "pri-subnet" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "ap-south-1b"
  

  tags = {
    Name = "private-sub-1-terra"
  }
}

resource "aws_route_table" "rt-private1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gt-1.id
  }

  tags = {
    Name = "rt-private-terra-1"
  }
}


resource "aws_route_table_association" "rt-ass-2" {
  subnet_id      = aws_subnet.pri-subnet.id
  route_table_id = aws_route_table.rt-private1.id
}


#nat gateway creation 

resource "aws_nat_gateway" "nat-gt-1" {
  allocation_id = aws_eip.ep-1.id
  subnet_id     = aws_subnet.pri-subnet.id

  tags = {
    Name = "gw-nat"
  }

}

resource "aws_eip" "ep-1" {

  domain   = "vpc"
}

resource "aws_instance" "ec2-2" {
    ami = var.ami_value
    instance_type = var.instance_type_value
    subnet_id = aws_subnet.pri-subnet.id
    security_groups = [aws_security_group.terra-sg-pub.id]
    
    tags = {
      Name = "ec2-terra-2"
    }
}