terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.region }
variable "region" { default = "us-west-2" }
# Add RDS, EKS, VPC modules as you iterate
