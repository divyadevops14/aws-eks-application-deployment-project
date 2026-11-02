#!/usr/bin/env bash
# Build the Docker image and push it to AWS ECR.
# Usage: ./scripts/ecr-push.sh [tag]      (default tag: v1)
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
REPO="eks-demo-app"
TAG="${1:-v1}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${REPO}:${TAG}"

echo "==> Making sure ECR repository '${REPO}' exists in ${REGION}"
aws ecr describe-repositories --repository-names "${REPO}" --region "${REGION}" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "${REPO}" --region "${REGION}" \
       --image-scanning-configuration scanOnPush=true >/dev/null

echo "==> Logging Docker in to ECR"
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

echo "==> Building image"
docker build -t "${REPO}:${TAG}" ./app

echo "==> Tagging and pushing ${IMAGE}"
docker tag "${REPO}:${TAG}" "${IMAGE}"
docker push "${IMAGE}"

echo "Done. Image: ${IMAGE}"
