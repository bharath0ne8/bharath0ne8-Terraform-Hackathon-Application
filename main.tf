terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0, < 4.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = ""    
  secret_key = "K"    
}

# Create a new SSH key pair
resource "aws_key_pair" "my_new_key_pair" {
  key_name   = "my-new-key-pair"    
  public_key = ""
}

resource "aws_vpc" "Hackathon-Application-VPC" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_subnet" "Hackathon-Application-Subnet" {
  vpc_id                  = aws_vpc.Hackathon-Application-VPC.id
  cidr_block              = "10.10.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

# Create an internet gateway
resource "aws_internet_gateway" "Hackathon-InternetGateway" {
  vpc_id = aws_vpc.Hackathon-Application-VPC.id
}

# Create a route table
resource "aws_route_table" "Hackathon-RouteTable" {
  vpc_id = aws_vpc.Hackathon-Application-VPC.id
}

# Create a default route to the internet gateway
resource "aws_route" "Hackathon-InternetRoute" {
  route_table_id         = aws_route_table.Hackathon-RouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Hackathon-InternetGateway.id
}

# Associate the subnet with the route table
resource "aws_route_table_association" "Hackathon-SubnetAssociation" {
  subnet_id      = aws_subnet.Hackathon-Application-Subnet.id
  route_table_id = aws_route_table.Hackathon-RouteTable.id
}

# Create a security group
resource "aws_security_group" "Hackathon-Application-SG" {
  name        = "my-security-group"
  description = "Allow inbound SSH and HTTP traffic"

  # Inbound rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule allowing all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Hackathon-Application-VM" {
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_new_key_pair.key_name
  security_group= aws_security_group.Hackathon-Application-SG
  subnet_id     = aws_subnet.Hackathon-Application-Subnet.id
}
resource "aws_lb" "Hackathon-Application-LB" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.Hackathon-Application-Subnet.id,
    aws_subnet.Hackathon-Application-AnotherSubnet.id
  ]
  
  enable_deletion_protection = false
}
