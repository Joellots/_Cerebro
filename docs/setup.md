# Pipeline setup

How to reproduce the Cerebro CI/CD pipeline end to end.

## 1. Provision the CI host *(optional)*

[`terraform/`](../terraform/) creates a VPC, public subnet, internet gateway, security group and a `t2.large` Ubuntu 24.04 EC2 instance in `us-east-1` to host Jenkins.

```bash
cd terraform
terraform init
terraform apply
```

Outputs include the instance's public IP and DNS name. Narrow the security group's `0.0.0.0/0` ingress rules to your own address range before using it for anything beyond a lab.

## 2. Configure Jenkins

Install the **Pipeline**, **Kubernetes**, **Credentials Binding** and **JUnit** plugins, connect Jenkins to a cluster with a `jenkins` namespace, and register the DinD pod template ([`k8s/jenkins-agent-dind.yaml`](../k8s/jenkins-agent-dind.yaml)) under the label `jenkins-agent-dind`.

Create these credentials:

| ID | Type | Used for |
|----|------|----------|
| `DB_CREDENTIALS` | Username / password | PostgreSQL user for the build stack |
| `joellots-dockerhub` | Username / password | Pushing to Docker Hub |
| `SEMGREP_APP_TOKEN` | Secret text | Semgrep scan |
| `gitops-repo` | Secret text | GitOps repository URL (host and path, no scheme) |
| `gitlab-credentials` | Username / password | Pushing to the GitOps repository |

## 3. Point Argo CD at the GitOps repository

Create an Argo CD `Application` that tracks the `main` branch of `gitops-cerebro` (Kustomize `base/` layout) with automated sync enabled.

## 4. Run a build

Trigger the job with parameters:

- `VERSION` — image tag to build and deploy (`v1.1.0`, `v1.2.0`, `v1.3.0`)
- `executeTests` — run the unit-test stage

Approve the deploy prompt when it appears. The pipeline rewrites the image tag in `gitops-cerebro/base/deployment.yaml`, pushes the commit, and Argo CD rolls it out on its next sync.

## Reports

Each run archives these as fingerprinted build artifacts:

| File | Source |
|------|--------|
| `test-results.xml` | pytest (JUnit format) |
| `gitleaks.json` | Secret scan |
| `semgrep.json` | Multi-language SAST |
| `bandit.json` | Python SAST |
| `checkov.test.xml` | IaC misconfiguration scan |
