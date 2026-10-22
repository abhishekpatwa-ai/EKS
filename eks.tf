# ---------- 2. EKS cluster + managed node group ----------
# AWS runs the control plane (API server, etcd, scheduler) across AZs.
# We only manage the worker nodes and the add-ons.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "eks-lab"
  cluster_version = "1.34" # check supported versions: aws eks describe-cluster-versions

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # nodes and pods stay private

  cluster_endpoint_public_access = true # lab: so kubectl works from the laptop

  # Access entry: whoever runs terraform apply (your SSO role) becomes cluster admin.
  # (Old way was the aws-auth ConfigMap.)
  enable_cluster_creator_admin_permissions = true

  # Managed add-ons: AWS keeps these compatible with the cluster version
  cluster_addons = {
    vpc-cni                = {} # pods get real VPC IPs (like awsvpc in ECS)
    coredns                = {} # service-name DNS
    kube-proxy             = {} # Service IP -> pod IP rules
    eks-pod-identity-agent = {} # lets pods get IAM roles (Pod Identity)
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}
