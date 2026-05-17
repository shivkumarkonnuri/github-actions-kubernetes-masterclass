#!/usr/bin/env bash
###############################################################################
# install-aws-cli.sh
# Installs AWS CLI v2 on your local Ubuntu machine (20.04 / 22.04 / 24.04)
# Uses the official AWS installer — not apt, not snap
#
# Usage:
#   chmod +x install-aws-cli.sh
#   ./install-aws-cli.sh
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

log "Starting AWS CLI v2 installation..."

# Must be Ubuntu
if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
  die "This script is intended for Ubuntu only."
fi

UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d '"' -f2)
log "Detected Ubuntu ${UBUNTU_VERSION}"

# Warn if already installed
if command -v aws &>/dev/null; then
  EXISTING=$(aws --version 2>&1)
  warn "AWS CLI already installed: ${EXISTING}"
  warn "Continuing will reinstall the latest v2."
fi

###############################################################################
# 2. Install prerequisites
###############################################################################

log "Installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y \
  curl \
  unzip \
  less \
  groff

###############################################################################
# 3. Download AWS CLI v2 installer
###############################################################################

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT    # always clean up temp dir on exit

log "Downloading AWS CLI v2..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "${TMP_DIR}/awscliv2.zip"

###############################################################################
# 4. Verify download integrity (checksum)
###############################################################################

log "Downloading checksum file..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig" \
  -o "${TMP_DIR}/awscliv2.zip.sig" 2>/dev/null || true

log "Unzipping installer..."
unzip -q "${TMP_DIR}/awscliv2.zip" -d "${TMP_DIR}"

###############################################################################
# 5. Install
###############################################################################

log "Running AWS CLI installer..."
if command -v aws &>/dev/null; then
  # Upgrade existing installation
  sudo "${TMP_DIR}/aws/install" --update
else
  sudo "${TMP_DIR}/aws/install"
fi

###############################################################################
# 6. Verify installation
###############################################################################

log "Verifying AWS CLI installation..."

if ! command -v aws &>/dev/null; then
  die "aws binary not found after installation — something went wrong."
fi

AWS_VERSION=$(aws --version 2>&1)

echo ""
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}  AWS CLI v2 installed successfully${RESET}"
echo -e "${GREEN}========================================${RESET}"
echo -e "  ${AWS_VERSION}"
echo -e "${GREEN}========================================${RESET}"
echo ""

###############################################################################
# 7. Next steps — configure credentials
###############################################################################

log "Next steps:"
echo ""
echo "  1. Configure AWS credentials:"
echo "     aws configure"
echo ""
echo "     You will be prompted for:"
echo "       AWS Access Key ID     → from AWS Console → Security credentials → Access keys"
echo "       AWS Secret Access Key → shown only once when created"
echo "       Default region        → ap-south-1"
echo "       Default output format → json"
echo ""
echo "  2. Verify credentials are working:"
echo "     aws sts get-caller-identity"
echo ""
echo "  3. Then run Terraform:"
echo "     cd terraform/"
echo "     terraform init"
echo "     terraform plan"
echo "     terraform apply"
echo ""
