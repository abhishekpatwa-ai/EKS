# ---------- 1. Network: own VPC, 2 AZs (same idea as the Uconia network, but standalone) ----------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "eks-lab"
  cidr = "10.50.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets  = ["10.50.101.0/24", "10.50.102.0/24"] # ALB + NAT
  private_subnets = ["10.50.1.0/24", "10.50.2.0/24"]     # nodes + pods

  enable_nat_gateway = true
  single_nat_gateway = true # lab: one NAT to save cost (prod: one per AZ)

  # Tags tell the AWS Load Balancer Controller where to put load balancers
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }          # internet-facing ALB
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 } # internal ALB
}
