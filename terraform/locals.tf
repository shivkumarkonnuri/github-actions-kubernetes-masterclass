locals {
  # Consistent name prefix for all resources
  name_prefix = "${var.project}-${var.environment}"

  # Resource-specific names
  instance_name = "${local.name_prefix}-kind-node"
  sg_name       = "${local.name_prefix}-kind-node-sg"

  # Path where the generated .pem file is written on your local machine
  pem_path = "${var.pem_output_dir}/${var.key_pair_name}.pem"

  # Common tags merged with per-resource tags
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
