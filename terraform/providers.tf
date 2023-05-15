# Lock terraform version
terraform {
  required_version = ">= 1.1.4, < 1.5.0"

    required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.29"
    }
    }
}

# Define provider 
provider "aws" {
  region     = "eu-north-1"
  access_key = "AKIAUNRVXJQKLZPIZ7HP"
  secret_key = "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"
}
