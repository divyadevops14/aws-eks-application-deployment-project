#!/usr/bin/env bash
# Deploy the app to the cluster (Deployment + Service with a public load balancer).
# Usage: ./scripts/deploy.sh [tag]      (default tag: v1)
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
REPO="eks-demo-app"
TAG="${1:-v1}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
IMAGE="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:${TAG}"

echo "==> Deploying image ${IMAGE}"
sed "s|IMAGE_PLACEHOLDER|${IMAGE}|" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml

echo "==> Waiting for pods to become ready"
kubectl rollout status deployment/eks-demo-app --timeout=180s

echo "==> Pods"
kubectl get pods -l app=eks-demo-app -o wide

echo "==> Service (the EXTERNAL-IP column shows the load balancer address; it can take 2-3 minutes to appear)"
kubectl get svc eks-demo-app
echo
echo "To print just the URL once ready:"
echo "  kubectl get svc eks-demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
