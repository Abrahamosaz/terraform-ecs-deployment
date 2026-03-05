
# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"]
# }

# resource "aws_security_group" "nginx_sg" {
#   name        = "nginx-sg"
#   description = "Allow SSH and HTTP"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description      = "SSH"
#     from_port        = 22
#     to_port          = 22
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   ingress {
#     description      = "HTTP"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = merge(
#     var.resource_tags,
#     {
#       Name = "${var.resource_tags["Project"]}-nginx-sg"
#     }
#   )
# }

# resource "aws_instance" "demo_ec2_instance" {
#   ami                         = data.aws_ami.ubuntu.id
#   instance_type               = "t3.micro"
#   subnet_id                   = aws_subnet.public_subnet[0].id
#   vpc_security_group_ids      = [aws_security_group.nginx_sg.id]
#   associate_public_ip_address = true

#   user_data = <<-EOF
#               #!/bin/bash
#               apt-get update -y
#               apt-get install -y nginx
#               systemctl enable nginx
#               systemctl start nginx
#               EOF

#   tags = merge(
#     var.resource_tags,
#     {
#       Name = "${var.resource_tags["Project"]}-demo-ec2-instance"
#     }
#   )
# }
