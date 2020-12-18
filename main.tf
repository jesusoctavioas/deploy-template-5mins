terraform {
  backend "http" {}

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

locals {
  common_tags = {
    source = "Five Minute Production - ${var.ENVIRONMENT_NAME}"
  }
}

provider "aws" {
}
