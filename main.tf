terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
    access_key = "AKIAW7G5VF4TFHYQAGDS"
    secret_key = "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"

}
##------------------------------------------------------------
## creating custom  VPC ##

resource "aws_vpc" "MY_VPC" {
  cidr_block       = "10.0.0.0/26"
  instance_tenancy = "default"

  tags = {
    Name = "MY_VPC"
  }
}

##------------------------------------------------------------
## creating  public subnet   ##

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.MY_VPC.id
  cidr_block = "10.0.0.0/28"

  tags = {
    Name = "public_subnet"
  }
}

##------------------------------------------------------------
## creating  public route table   ##

resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.MY_VPC.id
 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "public_RT"
  }
}

##------------------------------------------------------------
## Associate  public route table with public subnet  ##

resource "aws_route_table_association" "pub_Rt_pub_SN" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_RT.id
}

##------------------------------------------------------------
##  creating internet gatway for public RT  ##

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.MY_VPC.id

  tags = {
    Name = "IGW"
  }
}

##------------------------------------------------------------
##  creating private subnet   ##

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.MY_VPC.id
  cidr_block = "10.0.0.16/28"

  tags = {
    Name = "private_subnet"
  }
}

##------------------------------------------------------------
##  creating private RT for private_subnet   ##

resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.MY_VPC.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT_GW.id
  }

  tags = {
    Name = "private_RT"
  }
}

##------------------------------------------------------------
##  creating NAT Gateway for private route table   ##

resource "aws_nat_gateway" "NAT_GW" {
  allocation_id = aws_eip.Elastic_IP.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "NAT_GW"
  }
}

##------------------------------------------------------------
##  creating Elastic_IP for NAT_Gateway   ##

resource "aws_eip" "Elastic_IP" {
   depends_on = [aws_internet_gateway.IGW]
}

##------------------------------------------------------------
##  Associate Private route table with private subnet   ##

resource "aws_route_table_association" "pri_Rt_pri_SN" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_RT.id
}

##------------------------------------------------------------
##  create zip of lambda fuction file    ##

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "${local.path_of_lambda_zip}"
}


##------------------------------------------------------------
##  create AWS lambda fuction    ##

resource "aws_lambda_function" "hit_url_lambda" {
  filename         = "${local.path_of_lambda_zip}"
  function_name    = "hit_url"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda.hit_url"
  source_code_hash = "${filebase64sha256(local.path_of_lambda_zip)}"
  runtime          = "python3.7"

   environment {
    variables ={
      Subnet = aws_subnet.private_subnet.id
     }
  }

}

##------------------------------------------------------------
##  create AWs iam role for lambda fuction  ##

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = "${file("/iam_role.json")}"
  tags = {
    name = "lambda_role"
  }
}

##------------------------------------------------------------
##  create AWS iam role policy   ##

resource "aws_iam_role_policy" "lambda_role_policy" {
  name = "lambda_role_policy"
  role = aws_iam_role.lambda_role.id

  policy ="${file("/iam_role_policy.json")}"
}


