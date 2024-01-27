terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

}

resource "aws_subnet" "pub-sub-01" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Pub_Sub-01"
  }
}

resource "aws_subnet" "pub-sub-02" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Pub_Sub-02"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "My_IGW"
  }
}

resource "aws_route_table" "RTB" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  route_table_id = aws_route_table.RTB.id
  subnet_id = aws_subnet.pub-sub-01.id
}

resource "aws_route_table_association" "b" {
  route_table_id = aws_route_table.RTB.id
  subnet_id = aws_subnet.pub-sub-02.id
}

resource "aws_security_group" "mysg" {
  vpc_id = aws_vpc.myvpc.id
  name = "my-SG"

   ingress {
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    description = "all ssh traffic"
   }

   ingress {
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    description = "allow http traffic"
   }

   ingress {
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    description = "allow https traffic"
   }

   egress {
    from_port = 0
    to_port = 0
    protocol = -1 
    description = "outbound rule"
    cidr_blocks = ["0.0.0.0/0"]
   }
  
}

resource "aws_instance" "myyec2" {
  ami = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "jenkiiiii"
  subnet_id = aws_subnet.pub-sub-01.id
  associate_public_ip_address = "true"
  user_data = file("apache1.sh")
  security_groups = [aws_security_group.mysg.id]

  tags = {
    Name = "project-tf-01"
  }
}

resource "aws_instance" "myyec3" {
  ami = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key_name = "jenkiiiii"
  subnet_id = aws_subnet.pub-sub-02.id
  associate_public_ip_address = "true"
  user_data = file("apache2.sh")
  security_groups = [aws_security_group.mysg.id]

  tags = {
    Name = "project-tf-02"
  }
}

resource "aws_s3_bucket" "myS3" {
  bucket = "my-project-terraform-18-bucket-09"

  tags = {
    Name        = "My bucket"
  }
}

resource "aws_lb" "myalb" {
  name               = "project-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets = [aws_subnet.pub-sub-01.id, aws_subnet.pub-sub-02.id]
  

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.myS3.id
  #   prefix  = "project-lb"
  #   enabled = true
  # }
}

resource "aws_lb_target_group" "project-tg" {
  name     = "tf-project-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
  
}
 resource "aws_lb_target_group_attachment" "attach-01" {
  target_group_arn = aws_lb_target_group.project-tg.arn
  target_id = aws_instance.myyec2.id
  port = 80
 }

 resource "aws_lb_target_group_attachment" "attach-02" {
  target_group_arn = aws_lb_target_group.project-tg.arn
  target_id = aws_instance.myyec3.id
  port = 80
 }

 resource "aws_lb_listener" "listner-port" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"
  

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.project-tg.arn
    
  }
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
  
}



