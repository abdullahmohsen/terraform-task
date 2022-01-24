output "app_eip" {
  value = aws_eip.app_eip.*.public_ip
}
 
output "app_instance" {
    value = module.ec2-instance.id[0]
}