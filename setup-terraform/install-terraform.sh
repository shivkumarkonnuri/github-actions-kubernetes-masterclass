#!/usr/bin/env bash
###############################################################################
# install-terraform.sh
# Installs Terraform on your local Ubuntu machine (20.04 / 22.04 / 24.04)
# Uses the official HashiCorp apt repository — not snap, not tfenv
#
# Usage:
#   chmod +x install-terraform.sh
#   ./install-terraform.sh
###############################################################################

set -euo pipefail

###############################################################################
# Helpers
###############################################################################

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

log()  { echo -e "${GREEN}[INFO]${RESET}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

###############################################################################
# 1. Pre-flight checks
###############################################################################

log "Starting Terraform installation..."

# Must be Ubuntu
if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
  die "This script is intended for Ubuntu only."
fi

UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d '"' -f2)
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || grep VERSION_CODENAME /etc/os-release | cut -d '=' -f2)
log "Detected Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"

case "$UBUNTU_CODENAME" in
  focal|jammy|noble)
    log "Ubuntu ${UBUNTU_CODENAME} is supported." ;;
  *)
    warn "Ubuntu ${UBUNTU_CODENAME} is not officially tested — proceeding anyway." ;;
esac

# Warn if Terraform is already installed
if command -v terraform &>/dev/null; then
  EXISTING=$(terraform version | head -1)
  warn "Terraform is already installed: ${EXISTING}"
  warn "Continuing will upgrade or reinstall via apt."
fi

###############################################################################
# 2. Install prerequisites
###############################################################################

log "Updating apt cache..."
sudo apt-get update -y

log "Installing prerequisites..."
sudo apt-get install -y \
  gnupg \
  software-properties-common \
  curl \
  wget \
  unzip \
  lsb-release

###############################################################################
# 3. Add HashiCorp official apt repository
###############################################################################

log "Adding HashiCorp GPG key..."
wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verify the key fingerprint
log "Verifying HashiCorp GPG key fingerprint..."
gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint

log "Adding HashiCorp apt repository..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

###############################################################################
# 4. Install Terraform
###############################################################################

log "Updating apt cache with HashiCorp repo..."
sudo apt-get update -y

log "Installing Terraform..."
sudo apt-get install -y terraform

###############################################################################
# 5. Enable tab completion (bash and zsh)
###############################################################################

log "Setting up shell tab completion..."

# Bash
if [ -f ~/.bashrc ]; then
  if ! grep -q "terraform -install-autocomplete" ~/.bashrc; then
    terraform -install-autocomplete 2>/dev/null || true
    log "Bash completion enabled."
  else
    log "Bash completion already configured."
  fi
fi

# Zsh
if [ -f ~/.zshrc ]; then
  if ! grep -q "terraform -install-autocomplete" ~/.zshrc; then
    terraform -install-autocomplete 2>/dev/null || true
    log "Zsh completion enabled."
  else
    log "Zsh completion already configured."
  fi
fi

###############################################################################
# 6. Verify installation
###############################################################################

log "Verifying Terraform installation..."

if ! command -v terraform &>/dev/null; then
  die "terraform binary not found after installation — something went wrong."
fi

TF_VERSION=$(terraform version)

echo ""
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}  Terraform installed successfully${RESET}"
echo -e "${GREEN}========================================${RESET}"
echo -e "${TF_VERSION}"
echo -e "${GREEN}========================================${RESET}"
echo ""

###############################################################################
# 7. Verify AWS CLI is present (needed to run terraform with AWS provider)
###############################################################################

if command -v aws &>/dev/null; then
  AWS_VERSION=$(aws --version 2>&1)
  log "AWS CLI found: ${AWS_VERSION}"
else
  warn "AWS CLI not found."
  warn "Install it with:"
  warn "  curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscliv2.zip"
  warn "  unzip awscliv2.zip && sudo ./aws/install"
  warn "Then configure: aws configure"
fi

###############################################################################
# 8. Next steps
###############################################################################

echo ""
log "Next steps:"
echo "  1. Configure AWS credentials (if not done already):"
echo "     aws configure"
echo "     # Enter: AWS Access Key ID, Secret Access Key, region (ap-south-1), output (json)"
echo ""
echo "  2. Copy and fill in your terraform variables:"
echo "     cd terraform/"
echo "     cp terraform.tfvars.example terraform.tfvars"
echo "     # Edit terraform.tfvars — set my_ip, key_pair_name etc."
echo ""
echo "  3. Initialise and apply:"
echo "     terraform init"
echo "     terraform fmt      # format check"
echo "     terraform validate # syntax check"
echo "     terraform plan     # preview what will be created"
echo "     terraform apply    # provision EC2 + generate hosts.ini + .pem"
echo ""
echo "  4. Then install prerequisites on EC2 using Ansible:"
echo "     cd ../ansible/"
echo "     ansible-playbook -i hosts.ini playbook.yml"
echo ""
