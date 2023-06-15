provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "C:\\Users\\shlomic\\jenkis+consul\\terraform.tfstate"
  }
}



resource "aws_route_table" "private_route" {
  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${data.terraform_remote_state.vpc.outputs.nat_gateway_id}"
    }
  tags   = {
    Name = "private Route"
  }
}
resource "aws_subnet" "ec2_1" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  tags   = {
    Name = "ec2_1 subnet"
  }
}

resource "aws_subnet" "ec2_2" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  tags   = {
    Name = "ec2_2 subnet"
  }
}

resource "aws_subnet" "ec2_3" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  tags   = {
    Name = "ec2_3 subnet"
  }
}
resource "aws_route_table_association" "rts1" {
    subnet_id = "${aws_subnet.ec2_1.id}"
    route_table_id = "${aws_route_table.private_route.id}"
}
resource "aws_route_table_association" "rts2" {
    subnet_id = "${aws_subnet.ec2_2.id}"
    route_table_id = "${aws_route_table.private_route.id}"
}

resource "aws_route_table_association" "rts3" {
    subnet_id = "${aws_subnet.ec2_3.id}"
    route_table_id = "${aws_route_table.private_route.id}"
}

resource "aws_subnet" "sub_ec2_rds_1" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1a"
  tags   = {
    Name = "rds_1 subnet"
  }
  }

resource "aws_subnet" "sub_ec2_rds_2" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-1b"
  tags   = {
    Name = "rds_2 subnet"
  }
}


resource "aws_route_table_association" "rta1" {
    subnet_id = "${aws_subnet.sub_ec2_rds_1.id}"
    route_table_id = "${aws_route_table.private_route.id}"
}

resource "aws_route_table_association" "rta2" {
    subnet_id = "${aws_subnet.sub_ec2_rds_2.id}"
    route_table_id = "${aws_route_table.private_route.id}"
}

resource "aws_subnet" "alb_1" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.7.0/24"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "alb_2" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.8.0/24"
  availability_zone       = "us-east-1b"
}

resource "aws_subnet" "alb_3" {
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1c"
}

resource "aws_route_table_association" "alb_1" {
    subnet_id = "${aws_subnet.alb_1.id}"
    route_table_id = "${data.terraform_remote_state.vpc.outputs.public_route_table_id_alb_nat}"
}

resource "aws_route_table_association" "alb_2" {
    subnet_id = "${aws_subnet.alb_2.id}"
    route_table_id = "${data.terraform_remote_state.vpc.outputs.public_route_table_id_alb_nat}"
}

resource "aws_route_table_association" "alb_3" {
    subnet_id = "${aws_subnet.alb_3.id}"
    route_table_id = "${data.terraform_remote_state.vpc.outputs.public_route_table_id_alb_nat}"
}