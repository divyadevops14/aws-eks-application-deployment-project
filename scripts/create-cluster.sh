#!/usr/bin/env bash
# Create the EKS cluster. COSTS MONEY while it exists (about $0.20/hr). Takes ~15 min.
# Remember to run scripts/cleanup.sh when you finish each session.
set -euo pipefail

echo "==> Creating EKS cluster from eks/cluster.yaml (this takes about 15 minutes)"
eksctl create cluster -f eks/cluster.yaml

echo "==> Checking connection"
kubectl get nodes
echo "Cluster is ready. Do not forget to delete it when done: ./scripts/cleanup.sh"
