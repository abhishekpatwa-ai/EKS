output "cluster_name" {
  value = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Run this once so kubectl talks to the new cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region eu-west-1"
}

output "demo_bucket" {
  value = aws_s3_bucket.demo.id
}
