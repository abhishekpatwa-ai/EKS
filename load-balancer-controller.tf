# ---------- 3. AWS Load Balancer Controller: turns an Ingress into an ALB ----------
# Same job my Terraform did for the shared ALB on ECS, but driven by Kubernetes YAML.

# IAM role for the controller's service account (Pod Identity), with AWS's LB policy
module "aws_lbc_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name                            = "eks-lab-aws-lbc"
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.0"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
  set {
    name  = "region"
    value = "eu-west-1"
  }

  depends_on = [module.eks, module.aws_lbc_pod_identity]
}
