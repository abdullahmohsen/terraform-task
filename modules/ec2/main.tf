resource "random_shuffle" "subnets" { 
  input        = var.subnets
  result_count = 1
} 

module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.17.0"
 
  name = "task-${var.infra_env}"
 
  ami                    = var.instance_ami
  instance_type          = var.instance_size
  vpc_security_group_ids = var.security_groups
  subnet_id              = random_shuffle.subnets.result[0]
 
  root_block_device = [{
    volume_size = var.instance_root_device_size
    volume_type = "gp3"
  }]
 
  tags = merge(
  {
    Name        = "task-${var.infra_env}"
    Role        = var.infra_role
    Project     = "task.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  },
  var.tags
  )
}

 //Elastic ip address
resource "aws_eip" "app_eip" {
  count = (var.create_eip) ? 1 : 0
  vpc   = true
 
  lifecycle {
    prevent_destroy = true
  }
 
  tags = {
    Name        = "task-${var.infra_env}-web-address"
    Role        = var.infra_role
    Project     = "task.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}
 
resource "aws_eip_association" "eip_assoc" {
  count         = (var.create_eip) ? 1 : 0
  instance_id   = module.ec2-instance.id[0]
  allocation_id = aws_eip.app_eip[0].id
}