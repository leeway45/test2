# 1. Terraform 配置塊
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.78.0"
    }
  }

}


provider "aws" {
  region = "ap-northeast-1"

}