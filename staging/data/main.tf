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

variable db_user {
  type        = string
  description = "the database user"
}
 
variable db_pass {
  type        = string
  description = "the database password"
}

#data sources used:
data "aws_vpc" "vpc" {
  tags = {
    Name        = "task-${var.infra_env}-vpc"
    Project     = "task.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

data "aws_subnet_ids" "database_subnets" {
  vpc_id = data.aws_vpc.vpc.id
 
  tags = {
    Name        = "task-${var.infra_env}-vpc"
    Project     = "task.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
    Role        = "database"
  }
}


module "database" {
  source = "../../modules/rds"
 
  infra_env = var.infra_env
  instance_type = "db.t3.medium"
  subnets = data.aws_subnet_ids.database_subnets.ids
  vpc_id = data.aws_vpc.vpc.id
  master_username = var.db_user
  master_password = var.db_pass
}