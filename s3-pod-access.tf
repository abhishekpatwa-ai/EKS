# ---------- 4. Demo: a pod reads S3 with NO access keys (Pod Identity) ----------
# Same idea as the ECS task role, and the same OIDC-style trust as GitHub -> AWS.

resource "aws_s3_bucket" "demo" {
  bucket        = "eks-lab-demo-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # lab: delete with its objects
}

resource "aws_s3_object" "hello" {
  bucket  = aws_s3_bucket.demo.id
  key     = "hello.txt"
  content = "Hello from S3 - read by a pod with Pod Identity, no keys!"
}

# Who may assume the role: only the EKS Pod Identity service
data "aws_iam_policy_document" "pods_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "s3_reader" {
  name               = "eks-lab-s3-reader"
  assume_role_policy = data.aws_iam_policy_document.pods_trust.json
}

# What the role may do: least privilege, read this one bucket only
resource "aws_iam_role_policy" "s3_reader" {
  name = "read-demo-bucket"
  role = aws_iam_role.s3_reader.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = aws_s3_bucket.demo.arn },
      { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${aws_s3_bucket.demo.arn}/*" },
    ]
  })
}

# Link: service account "s3-reader" in namespace "default" -> this IAM role
resource "aws_eks_pod_identity_association" "s3_reader" {
  cluster_name    = module.eks.cluster_name
  namespace       = "default"
  service_account = "s3-reader"
  role_arn        = aws_iam_role.s3_reader.arn
}
