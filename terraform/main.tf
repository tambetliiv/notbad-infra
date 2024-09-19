provider "aws" {
  region = var.region
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "notbad"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "notbad-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}








variable "bitbucket_ip" {
  type    = list(string)
  default = [
    "13.52.5.0/25", "104.192.136.0/21", "185.166.140.0/22", "104.192.136.0/21", "13.52.5.96/28", "13.236.8.224/28",
    "18.184.99.224/28", "18.234.32.224/28", "18.246.31.224/28", "52.215.192.224/28", "104.192.137.240/28",
    "104.192.138.240/28", "104.192.140.240/28", "104.192.142.240/28", "104.192.143.240/28", "185.166.143.240/28",
    "185.166.142.240/28", "18.205.93.0/25", "18.234.32.128/25"
  ]
}

resource "aws_security_group" "ec2-test" {
  name        = "ec2-test"
  description = "Allow test access"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.bitbucket_ip
    content {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

}






















module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 3
      max_size     = 3
      desired_size = 3
    }
  }
}

