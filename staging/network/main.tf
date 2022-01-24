//Create VPC
//Create Subnets 
//Create Public Gateway
//Security Groups
//EC2
//RDS (MySQL)


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.72.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}


variable "infra_env" {
  type        = string
  description = "infrastructure enviroment"
  default     = "staging"
}

variable default_region {
  type = string
  description = "the region this infrastructure is in"
  default = "eu-central-1"
}
 
variable instance_size {
  type = string
  description = "ec2 web server size"
  default = "t2.micro"
}

module "vpc" {
  source = "../../modules/vpc"
  infra_env = var.infra_env
  vpc_cidr  = "10.0.0.0/17" //CIDR: Classless Inter-Domain Routing
  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"] 
  public_subnets = ["10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"]
  private_subnets = ["10.0.24.0/21", "10.0.32.0/21", "10.0.40.0/21"]
  database_subnets = ["10.0.48.0/21", "10.0.56.0/21", "10.0.64.0/21"]
}