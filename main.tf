terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# AWS Security Account

provider "aws" {
    alias = "aws_sa"

    access_key = var.sa_aws_key
    secret_key = var.sa_aws_secret
    region = "us-west-2"
  }




# Create S3 bucket for CloudTrail logs

resource "aws_s3_bucket" "cloudtrail" {
  bucket = var.cloudtrail_bucket_name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "cloudtrail-logs"
  }
}

# Create S3 bucket for AWS Config logs

resource "aws_s3_bucket" "config" {
  bucket = var.config_bucket_name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "config-logs"
  }
}

# Create CloudTrail

resource "aws_cloudtrail" "main" {
  name                          = "main-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = {
    Name = "main-cloudtrail"
  }
}

# Create AWS Config Recorder

resource "aws_config_configuration_recorder" "main" {
  name     = "main-configuration-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported   = true
    include_global_resource_types = true
  }
}

# Create AWS Config Delivery Channel

resource "aws_config_delivery_channel" "main" {
  name           = "main-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config.bucket
  sns_topic_arn  = aws_sns_topic.notifications.arn
}

# Ensure the Config Recorder is started

resource "aws_config_configuration_recorder_status" "main" {
  name      = aws_config_configuration_recorder.main.name
  is_recording = true
}

# Create IAM Role for AWS Config

resource "aws_iam_role" "config" {
  name = "config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "config-role"
  }
}

# Attach IAM Policy to AWS Config Role

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# CloudWatch configuration can include alarms, metrics, and log groups. 

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "example" {
  name = "/aws/lambda/example"

  retention_in_days = 14

  tags = {
    Name = "example-log-group"
  }
}

# Create CloudWatch Metric Alarm
resource "aws_cloudwatch_metric_alarm" "example" {
  alarm_name          = "example-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.notifications.arn]

  dimensions = {
    InstanceId = "i-12345678"
  }

  tags = {
    Name = "example-alarm"
  }
}

/*----------------------------------------------------------------------------------------------------------------------------------*/

# AWS Shared services account Resources

provider "aws" {
    alias = "aws_ssa"

    access_key = var.ssa_aws_key
    secret_key = var.ssa_aws_secret
    region = "us-west-2"
  }

#VPC

resource "aws_vpc" "ssa_vpc" {
  provider = aws.aws_ssa
  cidr_block = var.cidr_block_ssa_vpc

  tags {

    Name = var.ssa_vpc_name
  }
}

# Subnets

resource "aws_subnet" "private_subnet_ssa_1" {
 provider = aws.aws_ssa
 vpc_id            = aws_vpc.ssa_vpc.id
 cidr_block        = var.private_subnet_ssa_cidr1
 availability_zone = var.azs1_ssa
 
 tags = {
   Name = "bytepro-subnet-ad-private-1a"
 }
}

resource "aws_subnet" "private_subnet_ssa_2" {
 provider = aws.aws_ssa
 vpc_id            = aws_vpc.ssa_vpc.id
 cidr_block        = var.private_subnet_ssa_cidr2
 availability_zone = var.azs2_ssa
 
 tags = {
   Name = "bytepro-subnet-ad-private-1b"
 }
}

# Route Table

resource "aws_route_table" "private_rt1_ssa" {
  provider = aws.aws_ssa
  vpc_id = aws_vpc.ssa_vpc.id

  tags = {
    Name = var.private_rt1_ssa_name
  }
}

resource "aws_route_table_association" "rt1-subnet1_ssa" {
  provider = aws.aws_ssa
  subnet_id      = aws_subnet.private_subnet_ssa_1.id
  route_table_id = aws_route_table.private_rt1_ssa.id
  depends_on = [aws_subnet.private_subnet_ssa_1]
}

resource "aws_route_table" "private_rt2_ssa" {
  provider = aws.aws_ssa
  vpc_id = aws_vpc.ssa_vpc.id

  tags = {
    Name = var.private_rt2_ssa_name
  }
}

resource "aws_route_table_association" "rt2-subnet2_ssa" {
  provider = aws.aws_ssa
  subnet_id      = aws_subnet.private_subnet_ssa_2.id
  route_table_id = aws_route_table.private_rt2_ssa.id
  depends_on = [aws_subnet.private_subnet_ssa_2]
}

# EC2 Instance

resource "aws_network_interface" "ecc1_nic" {
  provider = aws.aws_ssa
  subnet_id   = aws_subnet.private_subnet_ssa_1.id

  tags = {
    Name = "ecc1-nic"
  }
}

resource "aws_instance" "ad_instance1" {
  provider = aws.aws_ssa
  ami           = "ami-07e278fe6c43b6aba" # windows server 2022 Datacenter Edition
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.ecc1_nic.id
    device_index         = 0
  }
  tags = {
    Name = "instance-1"
  }

}

resource "aws_network_interface" "ecc2_nic" {
  provider = aws.aws_ssa
  subnet_id   = aws_subnet.private_subnet_ssa_2.id

  tags = {
    Name = "ecc2-nic"
  }
}

resource "aws_instance" "ad_instance2" {
  provider = aws.aws_ssa
  ami           = "ami-07e278fe6c43b6aba" # windows server 2022 Datacenter Edition
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.ecc2_nic.id
    device_index         = 0
  }

tags = {
    Name = "instance-2"
  }

}

/*-------------------------------------------------------------------------------------------------------------------------------------------*/

# AWS Infrastructure Account Glide

provider "aws" {
    alias = "aws_iag"

    access_key = var.iag_aws_key
    secret_key = var.iag_aws_secret
    region = "us-east-2"
  }

# VPC

resource "aws_vpc" "iag_vpc" {
  provider = aws.aws_iag
  cidr_block = var.cidr_block_iag_vpc

  tags = {

    Name = var.iag_vpc_name
  }
}

# Subnets

resource "aws_subnet" "public_subnet_iag_1" {
 provider = aws.aws_iag
 vpc_id            = aws_vpc.iag_vpc.id
 cidr_block        = var.public_subnet_iag_cidr
 
 tags = {
   Name = "glide-subnet-dev-app-public"
 }
}

resource "aws_subnet" "private_subnet_iag_1" {
 provider = aws.aws_iag
 vpc_id            = aws_vpc.iag_vpc.id
 cidr_block        = var.private_subnet_iag_cidr1
 
 tags = {
   Name = "glide-subnet-dev-app-private"
 }
}

resource "aws_subnet" "private_subnet_iag_2" {
 provider = aws.aws_iag
 vpc_id            = aws_vpc.iag_vpc.id
 cidr_block        = var.private_subnet_iag_cidr2
 
 tags = {
   Name = "glide-subnet-prod-db-private"
 }
}


# Create Internet Gateway
resource "aws_internet_gateway" "igw_iag" {
  provider = aws.aws_iag
  vpc_id = aws_vpc.iag_vpc.id

  tags = {
    Name = "glide-igw"
  }
}


# Allocate Elastic IP for NAT Gateway
resource "aws_eip" "nat_ip_iag" {
  vpc = true
}

# Create NAT Gateway
resource "aws_nat_gateway" "ngw_iag" {
  allocation_id = aws_eip.nat_ip_iag.id
  subnet_id     = aws_subnet.public_subnet_iag_1.id

  tags = {
    Name = "glide-nat-gw"
  }
}

# Create Route Table for Public Subnet

resource "aws_route_table" "public_rt_iag" {
  provider = aws.aws_iag
  vpc_id = aws_vpc.iag_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_iag.id
  }

  tags = {
    Name = var.public_rt_iag_name
  }
}

# Associate Public Route Table with Public Subnet

resource "aws_route_table_association" "public1" {
  provider = aws.aws_iag
  subnet_id      = aws_subnet.public_subnet_iag_1.id
  route_table_id = aws_route_table.public_rt_iag.id
  depends_on = [aws_subnet.public_subnet_iag_1]
}

# Create Route Table for Private Subnets
resource "aws_route_table" "private_rt_iag" {
  vpc_id = aws_vpc.iag_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_iag.id
  }

  tags = {
    Name = var.private_rt_iag_name
  }
}

# Associate Private Route Table with Private Subnet 1

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private_subnet_iag_1.id
  route_table_id = aws_route_table.private_rt_iag.id
}

# Associate Private Route Table with Private Subnet 2
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private_subnet_iag_2.id
  route_table_id = aws_route_table.private_rt_iag.id
}

/*-----------------------------------------------------------------------------------------------------------------------------*/

