terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # tls provider — generates RSA key pair locally
    # Saves .pem to disk via local_file resource in main.tf
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    # local provider — writes generated files (hosts.ini, .pem) to disk
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
