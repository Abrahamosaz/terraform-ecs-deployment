output "vpc_id" {
    value = aws_vpc.my_vpc.id
}

output "public_subnet_availability_zones" {
  value = aws_subnet.public_subnet[*].availability_zone
}

output "private_subnet_availability_zones" {
  value = aws_subnet.private_subnet[*].availability_zone
}

output "public_subnet_ids" {
    value = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
    value = aws_subnet.private_subnet[*].id
}

output "nat_ip" {
    value = aws_eip.nat_ip.public_ip
}