
terraform {
  required_version = ">=1.4.6"
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.44.0"
    }
  }

  backend "s3" {
    bucket = "terraform-slack-notification"
    key    = "state"
    region = "ap-northeast-1"
  }
}
