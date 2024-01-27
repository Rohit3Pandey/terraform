# # provider "aws" {
# #   region = "us-east-1"
# #   access_key = "accesskey"
# #   secret_key = "secretkey"
# # } --> instead of that run "aws configure" in terminal. 



# resource "aws_vpc" "my_vpc_tf" {
#   cidr_block = "172.16.0.0/16"

#   tags = {
#     Name = "VPC-tf"
#   }
# }

# resource "aws_subnet" "my_subnet" {
#   vpc_id            = aws_vpc.my_vpc_tf.id
#   cidr_block        = "172.16.10.0/24"
#   availability_zone = "us-east-1a"

#   tags = {
#     Name = "Public-subnet"
#   }
# }

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Dev"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Igw-Tf"
  }
}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Tf-route-table"
  }
}

# resource "aws_route_table" "route-table-priv" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "Tf-route-table-priv"
#   }
# }

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {

    Name = "My-ipv4-subnet"
  }
}

# resource "aws_subnet" "my_subnet-priv" {
#     vpc_id            = aws_vpc.main.id
#     cidr_block        = "10.0.16.0/20"
#     availability_zone = "us-east-1b"
# }    

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.route-table.id
}


# resource "aws_route_table_association" "b" {
#   subnet_id      = aws_subnet.my_subnet-priv.id
#   route_table_id = aws_route_table.route-table-priv.id
# }

resource "aws_security_group" "allow_Web_traffic" {
  name        = "allow_traffic"
  description = "Allow inbound web traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_all_traffic"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_HTTPS_ipv4" {
  security_group_id = aws_security_group.allow_Web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTP_ipv4" {
  security_group_id = aws_security_group.allow_Web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH_ipv4" {
  security_group_id = aws_security_group.allow_Web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_Web_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  # from_port         = 0
  # to_port           = 0
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_Web_traffic.id]

  # attachment {
  #   instance     = aws_instance.my-first-server.id
  #   device_index = 1
  # }
}

resource "aws_eip" "EIP-09" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_instance" "my-first-server" {
  ami               = "ami-0c7217cdde317cfec"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  # associate_public_ip_address = "false"
  key_name  = "jenkiiiii"
  user_data = file("install_apache.tpl")

  # user_data = <<EOF
  # #!/bin/bash
  # sudo apt-get update 
  # sudo apt-get install nginx -y
  # sudo echo "hi terraform" >/var/www/html/index.nginx-debian.html
  # EOF

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id

  }

  tags = {
    Name = "Terraform-18"
  }
}

