variable "vpc_cidr" {
  type        = string
  description = "The IP range to use for the VPC"
  default     = "10.0.0.0/16"
}

variable "infra_env" {
  type        = string
  description = "infrastructure environment"
  default     = "production"
}

variable instance_size {
  type = string
  description = "ec2 web server size"
  default = "t2.micro"
}

# New variable
variable "azs" {
  type = list(string)
  description = "AZs to create subnets into"
}
 
# Simplified Variable
variable "public_subnets" {
  type = list(string)
  description = "subnets to create for public network traffic, one per AZ"
}
 
# Simplified Variable
variable "private_subnets" {
  type = list(string)
  description = "subnets to create for private network traffic, one per AZ"
}

variable "database_subnets" {
  type = list(string)
  description = "subnets to create for private network traffic, one per AZ"
}