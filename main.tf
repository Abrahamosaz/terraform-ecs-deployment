resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block


  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-main-vpc"
    }
  )

  region = var.region
}


resource "aws_subnet" "public_subnet" {
  count             = var.public_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-public-subnet-${count.index}"
    }
  )
}

resource "aws_subnet" "private_subnet" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-private-subnet-${count.index}"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-main-igw"
    }
  )
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.resource_tags,
    {
      Name = "${var.resource_tags["Project"]}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public_subnet_assoc" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

