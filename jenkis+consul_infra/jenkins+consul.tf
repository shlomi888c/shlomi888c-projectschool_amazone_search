provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main vpc"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
   tags = {
      Name = "Jenkins+consul EC2 route table"
  }
}

resource "aws_route_table" "public_alb_nat" {
  vpc_id = aws_vpc.main.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags   = {
    Name = "public Route alb"
  }
}

resource "aws_subnet" "ec2_4" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = "us-east-1a"
}



resource "aws_security_group" "jenkins-consul_sg" {
  name        = "jenkins_security_group"
  description = "Allow HTTP and SSH access"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8200
    to_port     = 8200
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
      Name = "Jenkins+consul EC2 route table"
  }

}

resource "aws_instance" "jenkins-consul" {
  ami                         = "ami-0574da719dca65348"
  instance_type               = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins-consul_sg.id]
  key_name                    = aws_key_pair.ec2_key.key_name
  subnet_id     = aws_subnet.ec2_4.id
  associate_public_ip_address = true
    user_data = <<-EOF
#!/bin/bash
echo "jenkins ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
mkdir -p /consul/data
echo '{
  "datacenter": "dc1",
  "data_dir": "/data/consul",
  "log_level": "INFO",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "ports": {
    "http": 8500
  }
}' > /consul/data/consul_config.json
echo '{
  "Name": "mysql_rds_service",
  "ID": "mysql_rds_service",
  "Tags": ["mysql", "rds"],
  "Check": {
    "Name": "MySQL RDS health check",
    "TCP": "test.ciignquihkpp.us-east-1.rds.amazonaws.com:3306",
    "Interval": "10s",
    "Timeout": "1s"
    }
  }' > /consul/data/rds.json
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install -y docker.io
sudo docker pull consul
sudo service docker start
sudo docker run -d --name=consul-server -v /consul/data -p 8500:8500 consul agent -server -bootstrap -client=0.0.0.0 -ui
sudo apt update -y && sudo apt upgrade -y
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get update && sudo apt-get install -y python3
sudo apt-get install -y python3-pip
sudo apt install openjdk-11-jre -y
sudo apt-get install jenkins -y
sudo dpkg --configure -a
sudo systemctl start jenkins
sudo systemctl status jenkinsexut
EOF
provisioner "file" {
    source      = local_file.TF-key.filename
    destination = "/home/ubuntu/tfkey"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa.private_key_pem
      host        = self.public_ip
    }
  }
  tags = {
      Name = "Jenkins+consul EC2 instance"
  }
}


resource "aws_key_pair" "ec2_key" {
  key_name   = "consul_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "TF-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfkey"
}

resource "aws_route_table_association" "jenkis-consul" {
    subnet_id = "${aws_subnet.ec2_4.id}"
    route_table_id = "${aws_route_table.main.id}"
}

# Define Elastic IP
 resource "aws_eip" "my_eip" {
   vpc = true
}

resource "aws_subnet" "nat" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.9.0/24"
  availability_zone       = "us-east-1a"
}

resource "aws_route_table_association" "nat" {
    subnet_id = "${aws_subnet.nat.id}"
    route_table_id = "${aws_route_table.public_alb_nat.id}"
}



# Define NAT Gateway
resource "aws_nat_gateway" "my_nat_gateway" {
   allocation_id = aws_eip.my_eip.id
   subnet_id     = aws_subnet.nat.id

  depends_on = [aws_internet_gateway.igw]
}



output "vpc_id" {
  value = aws_vpc.main.id
}

output "gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "my_key" {
  value = aws_key_pair.ec2_key.public_key
}

output "my_key_name" {
  value = aws_key_pair.ec2_key.key_name
}

output "nat_gateway_id" {
 value = aws_nat_gateway.my_nat_gateway.id
}
output "public_route_table_id_alb_nat" {
  value = aws_route_table.public_alb_nat.id
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins-consul.public_dns}:8080"
}
output "consul_url" {
  value = "http://${aws_instance.jenkins-consul.public_dns}:8500"
}

output "instance_public_ip" {
  value = aws_instance.jenkins-consul.public_ip
}