terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "cloudathon"
  assume_role {
    role_arn = "arn:aws:iam::037297136404:role/AdminRole"
  }
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "cloudathon"
  assume_role {
    role_arn = "arn:aws:iam::037297136404:role/AdminRole"
  }
}

provider "aws" {
  alias   = "us_west_2"
  region  = "us-west-2"
  profile = "cloudathon"
  assume_role {
    role_arn = "arn:aws:iam::037297136404:role/AdminRole"
  }
} 