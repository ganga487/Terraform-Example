provider "aws" {
  profile = "default"
  region  = "us-east-1"
  access_key = "AKIAUL5ARJBS7TNDX4UW"
  secret_key = "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"
}

resource "aws_vpc" "Gangavpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Gangavpc"
  }
}

resource "aws_subnet" "Public-subnet" {
  vpc_id     = aws_vpc.Gangavpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public-subnet"
  }
}

resource "aws_subnet" "Private-subnet" {
  vpc_id     = aws_vpc.Gangavpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-subnet"
  }
}

resource "aws_security_group" "Gangasg" {
  name        = "Gangasg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Gangavpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Gangasg"
  }
}

# This is for Internet gateway

resource "aws_internet_gateway" "Ganga-igw" {
  vpc_id = aws_vpc.Gangavpc.id

  tags = {
    Name = "Ganga-igw"
  }
}

# this eip for nat
resource "aws_eip" "Ganga-eip-nat" {
  vpc      = true

}

# This is for Nat gateway

resource "aws_nat_gateway" "Ganga-nat" {
  allocation_id = aws_eip.Ganga-eip-nat.id
  subnet_id     = aws_subnet.Private-subnet.id
}

# This is route table for IGW

resource "aws_route_table" "Gangaroute" {
  vpc_id = aws_vpc.Gangavpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Ganga-igw.id
  }

  tags = {
    Name = "Gangaroute"
  }
}

# This is route table for NAT gateway

resource "aws_route_table" "Gangaroutenat" {
  vpc_id = aws_vpc.Gangavpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.Ganga-nat.id
  }

  tags = {
    Name = "Gangaroutenat"
  }
}


# This is route table assaciation

resource "aws_route_table_association" "route-ass" {
  subnet_id      = aws_subnet.Public-subnet.id
  route_table_id = aws_route_table.Gangaroutenat.id
}

# This is route table assaciation for nat gateway

resource "aws_route_table_association" "route-assnat" {
  subnet_id      = aws_subnet.Private-subnet.id
  route_table_id = aws_route_table.Gangaroutenat.id
}

# This is Key-pair

resource "aws_key_pair" "Ganga-key" {
  key_name   = "Ganga-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIbDtEF91YWysulJKhlgAJAwgs9AKwY5jgnwIFl2hD484n5GNA+TnoeZ71TuJQEpIXW4bXvDsX921K+HJzBTJ3AhCFZPxOclwdrsnNEkamx6UnpIv3v44UC3/93QK89BxElqxiV5HPcgX014yv7Z1PAtPOa/xHSMwxRugR6hsZtiQzKWPXbEPBWcxKC8wyox7bc16MuZmZWkrfyzlX3mZa3w/pGG5Z3WQhVOQZZCxSO7BfvFI2kcCoIOMTak/O/0wrEarBA8oS/S77c0yoUE4+bJuNJFR27i4bhyLPK7Rxd824IlaDKul8LXO0fQ4LBrBztVNFl7zO140b+RF0PK8x root@ip-172-31-29-84.ec2.internal"

}

# This is for ec2 instance

resource "aws_instance" "Ganga-instance" {
  ami           = "ami-038f1ca1bd58a5790"
  instance_type = "t3.micro"
  key_name   = "Ganga-key"
  subnet_id  =  aws_subnet.Public-subnet.id
  vpc_security_group_ids = [aws_security_group.Gangasg.id]
  tags = {
    Name = "Ganga-instance"
  }
}

# This is for elastic ip

resource "aws_eip" "Ganga-eip" {
  instance = aws_instance.Ganga-instance.id
  vpc      = true
}

# This is for Database instance

resource "aws_instance" "Db-instance" {
  ami           = "ami-038f1ca1bd58a5790"
  instance_type = "t2.micro"
  key_name   = "Ganga-key"
  subnet_id  =  aws_subnet.Private-subnet.id
  vpc_security_group_ids = [aws_security_group.Gangasg.id]
  tags = {
    Name = "Db-instance"
  }
}



