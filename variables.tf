variable "ssa_aws_key" {
    default = "AKIAQ3EGWBEWPWCZOVHY"
}

variable "ssa_aws_secret" {
    default = "INbxe+PGHUpK+46T8j+4BnaKHC95q0iD+EoOJ19M"
}

variable "iag_aws_key" {
    default = "AKIAW3MEFZSP6XZMVPM6"
}

variable "iag_aws_secret" {
    default = "DTw0f94cGRIwTVJ2K+hwJthJm8FnT0IDZok/u1AM"
}

variable "sa_aws_key" {
    default = ""
}

variable "sa_aws_secret" {
    default = ""
}


variable "cidr_block_ssa_vpc" {
    default = "192.168.0.0/21"
}

variable "ssa_vpc_name" {
    default = "vpc-bytepro-sharedservices"
}

variable "private_rt1_ssa_name" {
    default = "private-rt-1"
}

variable "private_rt2_ssa_name" {
    default = "private_rt-2"
}

variable "private_subnet_ssa_cidr1" {
 description = "Private Subnet CIDR values"
 default     = "192.168.1.0/24"
}

variable "private_subnet_ssa_cidr2" {
 description = "Private Subnet CIDR values"
 default     = "192.168.2.0/24"
}

variable "azs1_ssa" {
 description = "Availability Zones"
 default     = "us-west-2a"
}

variable "azs2_ssa" {
 description = "Availability Zones"
 default     = "us-west-2b"
}



variable "cidr_block_iag_vpc" {
    default = "172.16.16.0/21"
}

variable "iag_vpc_name" {
    default = "vpc-glide-01"
}

variable "public_subnet_iag_cidr" {
 description = "Public Subnet CIDR values"
 default     = "172.16.16.0/26"
}

variable "private_subnet_iag_cidr1" {
 description = "Private Subnet CIDR values"
 default     = "172.16.16.64/27"
}

variable "private_subnet_iag_cidr2" {
 description = "Private Subnet CIDR values"
 default     = "172.16.16.96/27"
}

variable "public_rt_iag_name" {
    default = "public-rt"
}

variable "private_rt_iag_name" {
    default = "private-rt"
}


variable "region" {
  default = "us-west-2"
}

variable "sns_topic_name" {
  default = "cloud-notifications"
}

variable "cloudtrail_bucket_name" {
  default = "my-cloudtrail-logs-bucket"
}

variable "config_bucket_name" {
  default = "my-config-logs-bucket"
}