output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.kind_node.id
}

output "public_ip" {
  description = "EC2 public IP — update GitHub Secret EC2_HOST if instance is stopped/started"
  value       = aws_instance.kind_node.public_ip
}

output "public_dns" {
  description = "EC2 public DNS hostname"
  value       = aws_instance.kind_node.public_dns
}

output "security_group_id" {
  description = "Security group ID attached to the EC2 instance"
  value       = aws_security_group.kind_node.id
}

output "ami_id" {
  description = "Ubuntu 24.04 AMI ID that was used"
  value       = data.aws_ami.ubuntu_24.id
}

output "key_pair_name" {
  description = "AWS key pair name created by Terraform"
  value       = aws_key_pair.kind_node.key_name
}

output "pem_file_path" {
  description = "Path to the generated .pem private key on your local machine"
  value       = local_sensitive_file.pem.filename
}

output "hosts_ini_path" {
  description = "Path to the generated Ansible hosts.ini file"
  value       = local_file.hosts_ini.filename
}

output "ssh_command" {
  description = "Ready-to-run SSH command"
  value       = "ssh -i ${local.pem_path} ubuntu@${aws_instance.kind_node.public_ip}"
}

output "next_step" {
  description = "What to run after terraform apply"
  value       = "cd ../ansible && ansible-playbook -i hosts.ini playbook.yml"
}

