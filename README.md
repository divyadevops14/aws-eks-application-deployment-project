# Application Development and Deployment on AWS EKS

Build a small web app, package it with Docker, push it to AWS ECR, and run it on AWS EKS (Kubernetes) behind an AWS load balancer.

## Architecture

```
You -> Browser -> AWS Load Balancer -> Kubernetes Service -> Pods (2 copies of the app)
                                                               ^
                              Docker image pulled from AWS ECR ┘
```

## Tools

AWS CLI v2, Docker, kubectl, eksctl, Git, GitHub, (optional) Helm and Jenkins.

## Project structure

```
aws-eks-application-deployment/
├── app/
│   ├── server.js          # the web app (Node.js, no dependencies)
│   ├── package.json
│   ├── Dockerfile         # builds the image
│   └── .dockerignore
├── k8s/
│   ├── deployment.yaml    # runs 2 pods with health checks
│   ├── service.yaml       # public load balancer (simple option)
│   └── alb/
│       ├── service-clusterip.yaml   # ALB option, step 1
│       └── ingress.yaml             # ALB option, step 2
├── eks/
│   └── cluster.yaml       # eksctl cluster definition (cost-optimized)
├── scripts/
│   ├── ecr-push.sh              # build + push image to ECR
│   ├── create-cluster.sh        # create the EKS cluster
│   ├── deploy.sh                # deploy the app
│   ├── install-alb-controller.sh  # optional: AWS Load Balancer Controller
│   └── cleanup.sh               # delete everything that costs money
├── .gitignore
└── README.md
```

## Cost rules (read first)

Approximate running cost is $0.20-0.30 per hour while the cluster exists. The EKS control plane alone is about $73 per month if left on.

1. Build in sessions and run `./scripts/cleanup.sh` at the end of every session.
2. Keep a billing budget alert (Billing -> Budgets, for example $5 and $10).
3. Use IAM user credentials, never root keys. Never commit keys to Git.
4. Use one region only: `us-east-1`.

## Phase 0: Setup (free)

```bash
aws sts get-caller-identity     # ARN should end in :user/<your-iam-user>, not :root
docker run hello-world
kubectl version --client
eksctl version
git --version
```

## Phase 1: Run the app locally (free)

```bash
cd app
docker build -t eks-demo-app:v1 .
docker run --rm -p 3000:3000 eks-demo-app:v1
```

Open http://localhost:3000 and http://localhost:3000/health. Stop with Ctrl+C.

## Phase 2: Push the image to ECR (almost free)

From the repo root:

```bash
chmod +x scripts/*.sh
./scripts/ecr-push.sh v1
```

## Phase 3: Create the EKS cluster (costs start here)

```bash
./scripts/create-cluster.sh        # about 15 minutes
kubectl get nodes                  # should show 2 Ready nodes
```

## Phase 4: Deploy and expose

Simple option (Service of type LoadBalancer):

```bash
./scripts/deploy.sh v1
kubectl get svc eks-demo-app       # wait for EXTERNAL-IP / hostname
```

Open `http://<EXTERNAL-IP hostname>` in your browser. Refresh a few times to see different pod names.

ALB option (Phase 4b, after the simple option works):

```bash
kubectl delete -f k8s/service.yaml
./scripts/install-alb-controller.sh
kubectl apply -f k8s/alb/
kubectl get ingress eks-demo-app   # ADDRESS column = ALB hostname
```

## Phase 5: Monitor and troubleshoot

```bash
kubectl get pods                              # status of each pod
kubectl describe pod <pod-name>               # events, probe failures, image pull errors
kubectl logs <pod-name>                       # application logs
kubectl logs -l app=eks-demo-app --tail=50    # logs from all pods
kubectl get events --sort-by=.lastTimestamp   # recent cluster events
kubectl top nodes                             # needs metrics-server
kubectl scale deployment eks-demo-app --replicas=3
kubectl rollout status deployment/eks-demo-app
kubectl rollout undo deployment/eks-demo-app  # roll back a bad release
```

Common problems:

| Symptom | Likely cause | Check |
|---|---|---|
| `ImagePullBackOff` | Wrong image URL/tag, or image not pushed | `kubectl describe pod`, check ECR |
| `CrashLoopBackOff` | App crashes on start | `kubectl logs <pod> --previous` |
| Pod `Running` but `0/1` Ready | Readiness probe failing | Path/port of `/health` |
| `EXTERNAL-IP` stays `<pending>` | Load balancer still provisioning, or subnet/permission issue | `kubectl describe svc eks-demo-app` |
| Page does not open | Security group, wrong port, or LB not ready yet | Wait 2-3 min, check the target health in the EC2 console |

## Phase 6: Tear down (do this every session)

```bash
./scripts/cleanup.sh              # keeps the ECR image
./scripts/cleanup.sh --with-ecr   # also removes the ECR repository
```

## Phase 7 (optional): CI/CD with Jenkins

A `Jenkinsfile` that builds the image, pushes it to ECR, and runs `kubectl apply` will be added after the manual flow works.
