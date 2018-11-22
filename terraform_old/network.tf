resource "aws_vpc" "archivematica-vpc3" {
  cidr_block           = "${var.archivematica_vpc_ip_cidr_range}" # "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "archivematica-vpc3"
  }
}

resource "aws_internet_gateway" "archivematica-gateway" {
  vpc_id = "${aws_vpc.archivematica-vpc3.id}" # apparently you can only have one of these per VPC

  tags {
    Name = "archivematica-gateway"
  }
}

# I think this corresponds to a row in the 'Routes' section of a Route Table in the console
# often that row is just 0.0.0.0/0 -> an_internet_gateway
resource "aws_route" "archivematica-route" {
  route_table_id         = "${aws_vpc.archivematica-vpc3.main_route_table_id}" # apparently this is bad practice, the main route table is used for inter-subnet network access, so the internet gateway should apparently get a separate route table.
  destination_cidr_block = "0.0.0.0/0"                                         # all ip addresses other than those in the VPC range
  gateway_id             = "${aws_internet_gateway.archivematica-gateway.id}"
}

# NOTE: the Associates Course says when we create a route table it needs to be associated
# with subnets using a aws_route_table_association (see lecture 76 at 11:20), we should have one of these
# for every public subnet that we want to link to the Internet Gateway

resource "aws_subnet" "archivematica-subnet-public1" {
  count             = "1"
  cidr_block        = "10.0.1.0/24"
  vpc_id            = "${aws_vpc.archivematica-vpc3.id}"
  availability_zone = "eu-west-1a"

  map_public_ip_on_launch = "true"

  tags {
    name = "archivematica-subnet-public1"
  }
}

resource "aws_subnet" "archivematica-subnet-public2" {
  count             = "1"
  cidr_block        = "10.0.2.0/24"
  vpc_id            = "${aws_vpc.archivematica-vpc3.id}"
  availability_zone = "eu-west-1b"

  map_public_ip_on_launch = "true"

  tags {
    name = "archivematica-subnet-public2"
  }
}

resource "aws_subnet" "archivematica-subnet-private1" {
  count             = "1"
  cidr_block        = "10.0.3.0/24"
  vpc_id            = "${aws_vpc.archivematica-vpc3.id}"
  availability_zone = "eu-west-1a"

  map_public_ip_on_launch = "false"

  tags {
    name = "archivematica-subnet-private1"
  }
}

resource "aws_subnet" "archivematica-subnet-private2" {
  count             = "1"
  cidr_block        = "10.0.4.0/24"
  vpc_id            = "${aws_vpc.archivematica-vpc3.id}"
  availability_zone = "eu-west-1b"

  map_public_ip_on_launch = "false"

  tags {
    name = "archivematica-subnet-private2"
  }
}
