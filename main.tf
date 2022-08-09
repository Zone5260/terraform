# start by giveing a provider 
provider "aws" {
    region = backend.region
    access_key = backend.access_key
    secret_key = backend.secret_key
}
#createing a vpc 
resource "aws_vpc" "vpc-1" {

  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraforam-vpc"
  }
}
# subnet for vpc 
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.vpc-1.id                 
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pub-subnet-1"
  }
}
# internet gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    Name = "gatwway-terraform-vpc"
  }
}
# rote table 
resource "aws_route_table" "rote-table" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.igw.id
  }
# if you have ipv6
  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_internet_gateway.igw.id
  # }

  tags = {
    Name = "terraform-vpc-rote-table"
  }
}
# route table association
resource "aws_route_table_association" "rote-table-association" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.rote-table.id
}
# security group 
resource "aws_security_group" "terraform-vpc-security" {
  name        = "allow_web_ssh_traffic"
  description = "Allow Web inbound traffic with ssh"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_Https_Http_SSH"
  }
}
# network interface
resource "aws_network_interface" "network-interface" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.25"]
  security_groups = [aws_security_group.terraform-vpc-security.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}
# assign eip to the network interface

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.network-interface.id
  associate_with_private_ip = "10.0.1.25"
  depends_on                 =  [aws_internet_gateway.igw]
}


# create an instance with in the vpc 
resource "aws_instance" "test-terraform-instance" {
  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "AWS1"

  network_interface {
    device_index = 0 
    network_interface_id = aws_network_interface.network-interface.id

  }
  user_data = <<-EOF {
        #!/bin/bash
        sudo yum install httpd
        sudo systemclt start httpd
        sudo systemctl enable httpd
        sudo echo WebPage start with terraform with vpc connected < /var/www/html/index.html
        EOF
  } 
# useing Name will allow you name your resource
  tags = {
    Name = "ExampleAppServerInstance"
  }
}
