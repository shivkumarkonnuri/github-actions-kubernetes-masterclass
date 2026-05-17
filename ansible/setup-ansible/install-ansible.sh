#!/usr/bin/env bash
###############################################################################
# install-ansible.sh
# Installs Ansible on your local Ubuntu machine (20.04 / 22.04 / 24.04)
#
# Usage:
#   chmod +x install-ansible.sh
#   ./install-ansible.sh
#
# What this installs:
#   - Ansible (latest stable via official PPA)
#   - python3-boto3       (needed for any AWS dynamic inventory)
#   - python3-botocore    (AWS SDK core — boto3 dependency)
#   - sshpass             (needed if using password-based SSH, optional)
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

log "Starting Ansible installation..."

# Must be run on Ubuntu
if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
  die "This script is intended for Ubuntu only."
fi

# Read Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d '"' -f2)
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || grep VERSION_CODENAME /etc/os-release | cut -d '=' -f2)
log "Detected Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"

# Supported versions
case "$UBUNTU_CODENAME" in
  focal|jammy|noble)
    log "Ubuntu ${UBUNTU_CODENAME} is supported." ;;
  *)
    warn "Ubuntu ${UBUNTU_CODENAME} is not officially tested — proceeding anyway." ;;
esac

###############################################################################
# 2. Update apt and install prerequisites
###############################################################################

log "Updating apt cache..."
sudo apt-get update -y

log "Installing prerequisites..."
sudo apt-get install -y \
  software-properties-common \
  python3 \
  python3-pip \
  python3-boto3 \
  python3-botocore \
  sshpass \
  curl \
  git

###############################################################################
# 3. Add Ansible official PPA and install
###############################################################################

log "Adding Ansible PPA..."
sudo add-apt-repository --yes --update ppa:ansible/ansible

log "Installing Ansible..."
sudo apt-get install -y ansible

###############################################################################
# 4. Verify installation
###############################################################################

log "Verifying Ansible installation..."

ANSIBLE_VERSION=$(ansible --version | head -1)
ANSIBLE_PYTHON=$(ansible --version | grep "python version" || true)
ANSIBLE_CFG=$(ansible --version | grep "config file" || true)

echo ""
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}  Ansible installed successfully${RESET}"
echo -e "${GREEN}========================================${RESET}"
echo -e "  Version : ${ANSIBLE_VERSION}"
echo -e "  Python  : ${ANSIBLE_PYTHON}"
echo -e "  Config  : ${ANSIBLE_CFG}"
echo -e "${GREEN}========================================${RESET}"
echo ""

###############################################################################
# 5. Verify ansible-playbook and ansible-inventory are available
###############################################################################

for cmd in ansible ansible-playbook ansible-inventory ansible-galaxy; do
  if command -v "$cmd" &>/dev/null; then
    log "$cmd → $(command -v $cmd)"
  else
    die "$cmd not found after installation — something went wrong."
  fi
done

###############################################################################
# 6. Print next steps
###############################################################################

echo ""
log "Next steps:"
echo "  1. Run Terraform to provision EC2 and generate hosts.ini:"
echo "     cd terraform/"
echo "     terraform init"
echo "     terraform apply"
echo ""
echo "  2. Run the Ansible playbook to install Docker, kind, kubectl on EC2:"
echo "     cd ansible/"
echo "     ansible-playbook -i hosts.ini playbook.yml"
echo ""
echo "  3. Push code to GitHub — CI/CD workflows will trigger automatically."
echo ""
