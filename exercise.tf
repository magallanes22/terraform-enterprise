##### VARIABLES
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {
  default = "fernandomagallanes.pem"
}

variable "network_address_space" {
  default = "10.22.0.0/16"
}
variable "subnet_address_space" {
  default = "10.22.0.0/24"
}

variable "instance_name" { default = "fer-apache"}

data "aws_availability_zones" "available" {}

##### AWS

# Write terrafrom code that will accept a CIDR, and spin up networking 
# sufficient to launch an internet facing apache server. Then launch an 
# apache server running a virtualhost for the site www.foo.com. 
# Modularize as much as possible, so we can run this multiple times if 
# we need to.


provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

# VPC 


resource "aws_vpc" "vpc" {
  cidr_block = "${var.network_address_space}"
  enable_dns_hostnames = "true"

}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

}

resource "aws_subnet" "subnet" {
  cidr_block        = "${var.subnet_address_space}"
  vpc_id            = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "true"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags {
    "Name" = "fernando-subnet" 
  }

}


# Security Groups 
resource "aws_security_group" "apache-fer-sg" {
  name        = "apache-fer-sg"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    "Name" = "fernando-vpc" 
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 

resource "aws_instance" "apache" {
  ami           = "ami-759bc50a"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.apache-fer-sg.id}"]
  key_name        = "${var.key_name}"
  #associate_public_ip_address  = true
  
  
  connection {
    user        = "ubuntu"
    private_key = "${file(var.private_key_path)}"

  tags {
    "Name" = "fernando-apache" 
  }
  
  

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install apache2 -y",
      "sudo service apache2 start",
    ]
  }
 }
}
