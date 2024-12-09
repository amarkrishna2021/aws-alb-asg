resource "aws_vpc" "asg_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
      name = "yt_vpc"
    }
  
}

variable "vpc_availibility_zones" {
    type = list(string)
    description = "Availibility Zones"
    default = [ "eu-west-2a", "eu-west-2b" ]
  
}

#Create Subnet for vpc

resource "aws_subnet" "Publice_subnet" {
    vpc_id = aws_vpc.asg_vpc.id
    count = length(var.vpc_availibility_zones)
    cidr_block = cidrsubnet(aws_vpc.asg_vpc.cidr_block, 8 ,count.index +1)
    availability_zone = element(var.vpc_availibility_zones, count.index)

    tags = {
      name = "yt public subnet"
    }

}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.asg_vpc.id
    count = length(var.vpc_availibility_zones)
    cidr_block = cidrsubnet(aws_vpc.asg_vpc.cidr_block, 8 ,count.index+3)
    availability_zone = element(var.vpc_availibility_zones, count.index)

    tags = {
      name = "yt private subnet"
    }
  
}

# Create internet gateway

resource "aws_internet_gateway" "igw_vpc" {
    vpc_id = aws_vpc.asg_vpc.id

    tags = {
      name = " yt internet Gateway"
    }
  
}

# Create route table for the public subnet

resource "aws_route_table" "rt_public_subnet" {
    vpc_id = aws_vpc.asg_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_vpc.id

    }

    tags = {
      name = "rt public subnet"
    }  
}

resource "aws_route_table_association" "public_sub_association" {
    route_table_id = aws_route_table.rt_public_subnet.id
    count = length(var.vpc_availibility_zones)
    subnet_id = element(aws_subnet.Publice_subnet[*].id , count.index)
  
}


# create elastic IP for the natgateway

resource "aws_eip" "eip" {
    domain = "vpc"
    depends_on = [ aws_internet_gateway.igw_vpc ]
  
}

# Create NAT Gateway for private subnet

resource "aws_nat_gateway" "nat_gateway" {
    subnet_id = element(aws_subnet.private_subnet[*].id ,0)
    allocation_id = aws_eip.eip.id
    depends_on = [ aws_internet_gateway.igw_vpc ]

    tags = {
      name = " yt NAT gateway"
    }
  
}

# route table for the private subnet

resource "aws_route_table" "rt_private_sub" {
    vpc_id = aws_vpc.asg_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gateway.id
    }
    depends_on = [ aws_nat_gateway.nat_gateway ]

    tags = {
      name = " private subnet rt"
    }
  
}

resource "aws_route_table_association" "private_sub_association" {
    route_table_id = aws_route_table.rt_private_sub.id
    count = length(var.vpc_availibility_zones)
    subnet_id = element(aws_subnet.private_subnet[*].id, count.index)

  
}