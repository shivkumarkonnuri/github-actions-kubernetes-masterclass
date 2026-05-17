variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project name — used for resource names and tags"
  type        = string
  default     = "skillpulse"
}

variable "environment" {
  description = "Deployment environment (dev / staging / production)"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = <<-EOT
    EC2 instance type for the kind cluster node.
    t3.medium is the minimum for a 3-node kind cluster.
    India AWS accounts may have Fleet restrictions — t3.medium works fine.
  EOT
  type        = string
  default     = "t3.medium"
}

variable "volume_size_gb" {
  description = "Root EBS volume size in GB — kind images + Docker layers need space"
  type        = number
  default     = 30
}

variable "key_pair_name" {
  description = <<-EOT
    Name for the EC2 key pair that Terraform will create in AWS.
    The private key (.pem) is saved automatically to your local machine
    at the path defined by local.pem_path.
  EOT
  type        = string
  default     = "skillpulse-key"
}

variable "pem_output_dir" {
  description = "Local directory where the generated .pem file will be saved"
  type        = string
  default     = "~/.ssh"
}

variable "my_ip" {
  description = <<-EOT
    Your public IP in CIDR notation for SSH + app access.
    Find it with: curl ifconfig.me
    Example: 203.0.113.10/32
  EOT
  type        = string
}

variable "app_port" {
  description = "Host port that kind maps NodePort 30080 to (from kind-config.yaml)"
  type        = number
  default     = 8888
}

