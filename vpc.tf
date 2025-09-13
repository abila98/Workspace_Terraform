provider "aws" {
  region = "ap-south-1" # Change to your region
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "100.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "100.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}




resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "100.0.2.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Private Subnet"
  }
}


resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}


resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id   # NAT must be in a public subnet
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gateway"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
