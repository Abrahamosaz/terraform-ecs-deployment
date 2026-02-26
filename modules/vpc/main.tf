###############################################
#LOCALS VARIABLES
###############################################
locals {
  cluster_tag = var.eks_cluster_name != "default-eks-cluster" ? {
    "kubernetes.io/cluster/${var.env}-${var.eks_cluster_name}" = "owned"
  } : {}
}


###############################################
#VPC
###############################################
resource "aws_vpc" "my_vpc" {
  cidr_block        =  var.cidr_block
  instance_tenancy  = "default"
  
  
  enable_dns_support = true
  enable_dns_hostnames = true
  

  tags = {
    Name = "${var.env}-${var.name}"
  }
}

###############################################
#PUBLIC SUBNETS
###############################################
resource "aws_subnet" "public_subnet" {
    count                   = var.no_of_public_subnets
    vpc_id                  = aws_vpc.my_vpc.id
    cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
    availability_zone       = var.azs[count.index]
    map_public_ip_on_launch = true

    tags = merge(
        {
            Name = "${var.env}-public_subnet-${var.azs[count.index]}"
            "kubernetes.io/role/elb" = "1"
        },
        local.cluster_tag
    )
}

###############################################
#PRIVATE SUBNETS
###############################################
resource "aws_subnet" "private_subnet" {
    count                   =  var.no_of_private_subnets
    vpc_id                  =  aws_vpc.my_vpc.id
    cidr_block              =  cidrsubnet(var.cidr_block, 8, count.index + var.no_of_public_subnets)
    availability_zone       =  var.azs[count.index]

    tags = merge(
        {
            Name = "${var.env}-private_subnet-${var.azs[count.index]}"
            "kubernetes.io/role/internal-elb" = "1"
        },
        local.cluster_tag
    )
}


###############################################
#INTERNET GATEWAY
###############################################
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.my_vpc.id

    tags = {
        Name = "${var.env}-IGW"
    }
}


###############################################
#NAT(NETWORK ADDRESS TRANSLATION) GATEWAY
###############################################
resource "aws_nat_gateway" "ngw" {
    allocation_id = aws_eip.nat_ip.id
    subnet_id     = aws_subnet.public_subnet[0].id

    tags = {
        Name = "${var.env}-NGW"
    }

    depends_on = [aws_internet_gateway.gw]
}



###############################################
#ELASTIC IP
###############################################
resource "aws_eip" "nat_ip" {
    domain   = "vpc"

    tags = {
        Name = "${var.env}-NAT-EIP"
    }
}


###############################################
#PUBLIC ROUTE TABLE
###############################################
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    tags = {
        Name = "${var.env}-public"
    }
}

resource "aws_route" "public_r" {
    for_each                  = toset(var.public_routes_cidr_blocks)
    route_table_id            = aws_route_table.public_route_table.id
    destination_cidr_block    = each.value
    gateway_id                = aws_internet_gateway.gw.id
}


###############################################
#PRIVATE ROUTE TABLE
###############################################
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    tags = {
        Name = "${var.env}-private"
    }
}

resource "aws_route" "private_r" {
    for_each                  = toset(var.private_routes_cidr_blocks)
    route_table_id            = aws_route_table.private_route_table.id
    destination_cidr_block    = each.value
    nat_gateway_id            = aws_nat_gateway.ngw.id
}


###############################################
#PUBLIC TABLE ASSOCIATION
###############################################
resource "aws_route_table_association" "public_a" {
    count          = var.no_of_public_subnets
    subnet_id      = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}


###############################################
#PRIVATE TABLE ASSOCIATION
###############################################
resource "aws_route_table_association" "private_a" {
   count          = var.no_of_private_subnets
   subnet_id      = aws_subnet.private_subnet[count.index].id
   route_table_id = aws_route_table.private_route_table.id
}