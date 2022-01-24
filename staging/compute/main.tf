terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.72.0"
    }
  }

  # Add in the backend configuration
  # backend "s3" {
  #   region  = "eu-central-1"
  #   profile = "default"
  # }
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

data "aws_ami" "app" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical official
}


data "aws_vpc" "vpc" {
  tags = {
    Name        = "task-${var.infra_env}-vpc"
    Project     = "task.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}
 
# data "aws_subnet_ids" "public_subnets" {
#   vpc_id = data.aws_vpc.vpc.id
 
#   tags = {
#     Name        = "task-${var.infra_env}-vpc"
#     Project     = "task.io"
#     Environment = var.infra_env
#     ManagedBy   = "terraform"
#     Role        = "public"
#   }
# }
 
data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.vpc.id
 
  tags = {
    Name        = "task-${var.infra_env}-vpc"
    Project     = "task.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
    Role        = "private"
  }
}
 
# data "aws_security_groups" "public_sg" {
#   tags = {
#     Name        = "task-${var.infra_env}-public-sg"
#     Role        = "public"
#     Project     = "task.io"
#     Environment = var.infra_env
#     ManagedBy   = "terraform"
#   }
# }
 
data "aws_security_groups" "private_sg" {
  tags = {
    Name        = "task-${var.infra_env}-private-sg"
    Role        = "private"
    Project     = "task.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

module "ec2_worker" {
  source = "../../modules/ec2"
  
  infra_env = var.infra_env
  infra_role = "worker"
  instance_size = var.instance_size
  instance_ami = data.aws_ami.app.id
  instance_root_device_size = 20

  subnets = data.aws_subnet_ids.private_subnets.ids
  security_groups = data.aws_security_groups.private_sg.ids

  tags = {
    Name = "task-${var.infra_env}-worker"
  }
  create_eip = false
}

# module "ec2_app" {
#   source = "../../modules/ec2"
  
#   infra_env = var.infra_env
#   infra_role = "web"
#   instance_size = var.instance_size
#   instance_ami = data.aws_ami.app.id

#   subnets = data.aws_subnet_ids.public_subnets.ids # Note: Public subnets 
#   security_groups = data.aws_security_groups.public_sg.ids # TODO: Create security groups

#   tags = {
#     Name = "task-${var.infra_env}-web"
#   }
#   create_eip = true
# }