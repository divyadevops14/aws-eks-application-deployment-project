#!/usr/bin/env bash
# OPTIONAL (Phase 4b): install the AWS Load Balancer Controller so an Ingress can create an ALB.
# Requires: cluster running, helm installed, eks/cluster.yaml created with iam.withOIDC: true.
#
# NOTE: check the latest controller release in the AWS docs before running and update
# LBC_VERSION. The IAM policy must match the controller version. We will verify this together.
set -euo pipefail

CLUSTER="eks-demo"
REGION="${AWS_REGION:-us-east-1}"
LBC_VERSION="${LBC_VERSION:-v2.13.0}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

echo "==> Downloading IAM policy for controller ${LBC_VERSION}"
curl -fsSL -o iam_policy.json \
  "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${LBC_VERSION}/docs/install/iam_policy.json"

echo "==> Creating IAM policy (ignored if it already exists)"
aws iam create-policy --policy-name "${POLICY_NAME}" \
  --policy-document file://iam_policy.json >/dev/null 2>&1 || echo "Policy already exists, continuing"

echo "==> Creating service account linked to the IAM policy"
eksctl create iamserviceaccount \
  --cluster "${CLUSTER}" --region "${REGION}" \
  --namespace kube-system --name aws-load-balancer-controller \
  --attach-policy-arn "${POLICY_ARN}" \
  --override-existing-serviceaccounts --approve

echo "==> Installing controller with Helm"
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="${CLUSTER}" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=180s
rm -f iam_policy.json
echo "Controller installed. Now: kubectl delete -f k8s/service.yaml; kubectl apply -f k8s/alb/"
