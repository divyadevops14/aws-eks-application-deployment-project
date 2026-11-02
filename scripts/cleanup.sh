#!/usr/bin/env bash
# Delete everything that costs money. Run this at the END of every session.
# Usage: ./scripts/cleanup.sh              (deletes load balancer + cluster, keeps the ECR image)
#        ./scripts/cleanup.sh --with-ecr   (also deletes the ECR repository)
set -uo pipefail

CLUSTER="eks-demo"
REGION="${AWS_REGION:-us-east-1}"

echo "==> 1/3 Deleting Kubernetes resources first (this removes the AWS load balancer)"
kubectl delete -f k8s/alb/ --ignore-not-found 2>/dev/null
kubectl delete -f k8s/service.yaml --ignore-not-found
kubectl delete -f k8s/deployment.yaml --ignore-not-found 2>/dev/null
echo "Waiting 60s for AWS to remove the load balancer..."
sleep 60

echo "==> 2/3 Deleting the EKS cluster (about 10 minutes)"
eksctl delete cluster --name "${CLUSTER}" --region "${REGION}" --wait

if [ "${1:-}" = "--with-ecr" ]; then
  echo "==> Deleting ECR repository"
  aws ecr delete-repository --repository-name eks-demo-app --region "${REGION}" --force
fi

echo "==> 3/3 Checking for leftovers (all lists below should be empty)"
echo "-- Load balancers:"
aws elbv2 describe-load-balancers --region "${REGION}" --query 'LoadBalancers[].LoadBalancerName' --output text
aws elb describe-load-balancers --region "${REGION}" --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text
echo "-- NAT gateways (available):"
aws ec2 describe-nat-gateways --region "${REGION}" --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId' --output text
echo "-- Unattached volumes:"
aws ec2 describe-volumes --region "${REGION}" --filters Name=status,Values=available --query 'Volumes[].VolumeId' --output text
echo "-- EKS clusters:"
aws eks list-clusters --region "${REGION}" --query 'clusters' --output text
echo "Also glance at the Billing console tomorrow to confirm charges have stopped."
