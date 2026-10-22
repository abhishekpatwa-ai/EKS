# EKS learning lab

Standalone lab to understand EKS. Not related to the Uconia repos. Local Terraform state. Destroy after use (~$0.30/hour).

## Files

| File | What it creates |
|---|---|
| `vpc.tf` | VPC, 2 public + 2 private subnets, 1 NAT, subnet tags for load balancers |
| `eks.tf` | EKS cluster (AWS-managed control plane), managed node group (2 × t3.medium), add-ons |
| `load-balancer-controller.tf` | AWS Load Balancer Controller (Helm) + its IAM role via Pod Identity |
| `s3-pod-access.tf` | Demo S3 bucket + IAM role + Pod Identity association for service account `s3-reader` |
| `k8s/app.yaml` | nginx Deployment, Service, Ingress → ALB |
| `k8s/s3-reader.yaml` | Pod that reads S3 with no keys |

## Build (~25 min)

```powershell
aws sso login --profile learn
$env:AWS_PROFILE = "learn"
cd C:\Users\Admin\eks-lab
terraform init
terraform apply
aws eks update-kubeconfig --name eks-lab --region eu-west-1
kubectl get nodes
```

## Try it

```powershell
kubectl apply -f k8s/app.yaml
kubectl get pods -o wide          # pod IPs are real VPC IPs (VPC CNI)
kubectl get ingress hello         # ADDRESS = ALB DNS name (takes ~2 min)

kubectl apply -f k8s/s3-reader.yaml
kubectl logs s3-reader            # reads hello.txt, and ListAllMyBuckets is denied
```

## Destroy (order matters)

The ALB was created by Kubernetes, not Terraform, so delete the Ingress first or the VPC can't be deleted.

```powershell
kubectl delete -f k8s/s3-reader.yaml
kubectl delete -f k8s/app.yaml    # removes the ALB
terraform destroy
```
