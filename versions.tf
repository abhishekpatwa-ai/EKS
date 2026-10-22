# EKS learning lab — completely separate from the Uconia repos.
# Local state on purpose: this is a throwaway lab, destroyed after use.

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "aws" {
  region = "eu-west-1" # login: aws sso login --profile learn, and AWS_PROFILE=learn

  default_tags {
    tags = { Project = "eks-lab" }
  }
}

# Helm talks to the cluster with a short-lived token from `aws eks get-token`
# (same idea as `aws sso login`: no stored keys).
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "eu-west-1"]
    }
  }
}

data "aws_caller_identity" "current" {}
