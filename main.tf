provider "aws" {
    region                  =   "eu-central-1"
}

resource "aws_vpc" "vpc" {
    cidr_block              =   "10.0.0.0/16"
    instance_tenancy        =   "default"
    enable_dns_hostnames    =   true
}

resource "aws_internet_gateway" "internet-gateway" {
    vpc_id                  =   aws_vpc.vpc.id
}

resource "aws_subnet" "public-subnet" {
    vpc_id                  =   aws_vpc.vpc.id
    cidr_block              =   "10.0.0.0/24"
    availability_zone       =   "eu-central-1a"
    map_public_ip_on_launch =   true
}

resource "aws_route_table" "public-route-table" {
    vpc_id                  =   aws_vpc.vpc.id
    route {
        cidr_block          =   "0.0.0.0/0"
        gateway_id          =   aws_internet_gateway.internet-gateway.id
    }
}

resource "aws_route_table_association" "public-subnet-1-assoc" {
    subnet_id               =   aws_subnet.public-subnet.id
    route_table_id          =   aws_route_table.public-route-table.id
}

resource "aws_subnet" "private-subnet" {
    vpc_id                  =   aws_vpc.vpc.id
    cidr_block              =   "10.0.2.0/24"
    availability_zone       =   "eu-central-1a"
    map_public_ip_on_launch =   false
}

resource "aws_security_group" "security-group" {
    name                    =   "dynamic security"
    vpc_id                  =   aws_vpc.vpc.id
    dynamic "ingress" {
        for_each = ["80", "443"]
        content {
        from_port   = ingress.value
        to_port     = ingress.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
}

resource "aws_instance" "web" {
    ami                     =   "ami-095e0f8062e0e8216"
    instance_type           =   "t2.micro"
    security_groups         =   ["${aws_security_group.security-group.id}"]
    subnet_id               =   "${aws_subnet.public-subnet.id}"
    associate_public_ip_address =   true
    user_data               =   file("user_data.sh")
}
