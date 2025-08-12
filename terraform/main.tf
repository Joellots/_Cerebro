
resource "aws_internet_gateway" "runner_igw" {
  vpc_id = aws_vpc.runner_vpc.id
  tags = {
    Name = "runner_igw"
  }
}

resource "aws_route_table" "runner_route_table" {
  vpc_id = aws_vpc.runner_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.runner_igw.id
  }
}

resource "aws_route_table_association" "runner_rta" {
  subnet_id      = aws_subnet.runner_subnet.id
  route_table_id = aws_route_table.runner_route_table.id
}



# VPC
resource "aws_vpc" "runner_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "runner_vpc"
  }
}

# Subnet
resource "aws_subnet" "runner_subnet" {
  vpc_id            = aws_vpc.runner_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone
  tags = {
    Name = "runner_subnet"
  }
}

# Security Group
resource "aws_security_group" "runner-sec-grp" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.runner_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "Allow ping"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  

  tags = {
    Name = "runner_sec_grp"
  }
}

# EC2 Instance - runner
resource "aws_instance" "runner" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.runner_subnet.id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.runner-sec-grp.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 25  
    volume_type = "gp3" 
  }

  tags = {
    Name = "runner"
  }
}

