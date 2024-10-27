provider "aws" {
    region = "eu-west-2"
}

resource "aws_security_group" "my_sg"{
    name = "c14-kurt-martin-sg"
    description = "Security group for data engineering week 1 coursework"
    vpc_id = var.vpc_id

      # Ingress rules (allowing inbound traffic)
  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Allow all IPs to connect on port 80
  }

  ingress {
    description      = "Allow"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Allow all IPs to connect on port 22
  }

  # Egress rules (allowing outbound traffic)
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
} 


resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = var.db_instance_class
  db_name              = "c14_kurt_martin_museum"
  username             = var.db_username
  password             = var.db_password
  publicly_accessible  = true
  skip_final_snapshot  = true
  storage_type         = "gp2"
  db_subnet_group_name   = "c14-public-subnet-group"
  vpc_security_group_ids = [aws_security_group.my_sg.id]

  identifier = "c14-kurt-museum-db"

  deletion_protection = false

  multi_az             = false
  backup_retention_period = 7
}

# Lookup the existing subnet by name
data "aws_subnet" "public_subnet" {
  filter {
    name   = "tag:Name"  
    values = ["c14-public-subnet-1"]  
  }
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-0acc77abdfc7ed5a6"  
  instance_type = "t3.micro"               
  subnet_id = data.aws_subnet.public_subnet.id
  key_name = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.my_sg.id]

  tags = {
    Name = "c14-kurt-martin-ec2"
  }
}



