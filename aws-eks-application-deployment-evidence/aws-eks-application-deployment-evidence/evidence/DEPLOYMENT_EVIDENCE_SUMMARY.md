# AWS EKS Application Development and Deployment — Evidence Summary

## Project overview

This project demonstrates a small Node.js web application packaged with Docker, stored in Amazon Elastic Container Registry (ECR), and deployed to Amazon Elastic Kubernetes Service (EKS). The application is exposed through an AWS Application Load Balancer (ALB), with Kubernetes managing two application pod replicas.

**AWS Region:** `us-east-1`  
**ECR repository:** `eks-demo-app`  
**Container image tag shown:** `v1`  
**EKS cluster:** `eks-demo`  
**EKS managed node group:** `demo-nodes`  
**Application deployment/service/ingress:** `eks-demo-app`

## Evidence captured

| # | Evidence file | What it demonstrates |
|---|---|---|
| 1 | `01-project-architecture-overview.png` | Project architecture, tools, repository structure, deployment workflow, and key highlights. |
| 2 | `02-local-docker-app-test.jpg` | Docker image `eks-demo-app:v1` exists locally; the container starts and serves the application on port `3000`. The browser displays the app's welcome page. |
| 3 | `03-ecr-repository-and-image-push.jpg` | ECR login succeeds and Docker image layers are pushed to the ECR repository. The `v1` image tag is visible in the ECR console. |
| 4 | `04-ecr-repository-creation.jpg` | ECR repository `eks-demo-app` is created in account `131696162455` in `us-east-1`; image scanning on push is enabled and encryption is AES-256. |
| 5 | `05-eks-nodegroup-and-kubernetes-health.jpg` | EKS node group `demo-nodes` reports `ACTIVE`; the CLI output shows one Kubernetes node in `Ready` state and the visible `kube-system` pods running. The EKS console panel showed `Nodes (0)` at the time of capture, so the console and CLI views were not fully aligned in this screenshot. |
| 6 | `06-eks-application-alb-deployment.jpg` | Deployment rollout completes; two application pods are `Running` and `1/1 Ready`; the Kubernetes Ingress has an ALB hostname; `curl` returns HTTP `200 OK`; `/health` returns `{"status":"ok"}`; and the browser displays the app through the ALB endpoint. |
| 7 | `07-jenkins-pipeline-stage-view.jpg` | Jenkins job `aws-eks-ecr-cicd-pipeline` Stage View. Build `#3` is successful with the displayed stages green. Builds `#1` and `#2` show failures in the ECR push / EKS deployment / verification stages, so the evidence records both the successful run and earlier failed attempts. |

## End-to-end workflow demonstrated

1. **Build and run locally:** Build the Docker image and verify the app at `http://localhost:3000`.
2. **Publish to ECR:** Authenticate Docker to ECR and push `eks-demo-app:v1`.
3. **Provision/use EKS:** Use the `eks-demo` cluster and its `demo-nodes` managed node group.
4. **Deploy to Kubernetes:** Deploy the app with two replicas and verify pod readiness and rollout status.
5. **Expose the app:** Use an ALB-backed Kubernetes Ingress to provide an external endpoint.
6. **Verify:** Confirm the web page responds, the root endpoint returns HTTP 200, and `/health` returns `{"status":"ok"}`.
7. **Automate:** The Jenkins Stage View records a successful pipeline run in build `#3`.

## Important notes and evidence boundaries

- The screenshots are point-in-time evidence, not a live status check. AWS resources may have changed since they were captured.
- The EKS compute screenshot contains a console/CLI discrepancy: the console shows `Nodes (0)`, while the terminal shows one node as `Ready`. The CLI result is recorded as shown rather than silently treating the console panel as proof of two nodes.
- The Jenkins screenshot shows build `#3` successful; builds `#1` and `#2` failed in later stages. It does not establish that every pipeline run succeeded.
- The screenshots show the ALB Ingress hostname and a successful HTTP response from that endpoint. They do not independently prove HTTPS/TLS configuration, custom DNS, autoscaling, or production readiness.
- The project overview diagram describes the intended architecture. The terminal and console screenshots provide the implementation evidence listed above.

## Cost and cleanup reminder

EKS control planes, EC2 worker nodes, and load balancers can incur charges while they exist. After finishing a work session, inspect the resources and run the project's cleanup script when you no longer need the environment:

```bash
./scripts/cleanup.sh
```

To remove the ECR repository as well (if that is intended):

```bash
./scripts/cleanup.sh --with-ecr
```

Check the script and AWS resource state before running cleanup. Keep any ECR image you still need by using the default cleanup option.

---
*Prepared from the project screenshots supplied for this evidence pack.*
