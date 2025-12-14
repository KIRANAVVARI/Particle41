
---

#`README.md`#🚀 Particle41 DevOps Challenge Solution: SimpleTimeServiceThis repository contains the solution for the Particle41 DevOps Challenge, demonstrating an Infrastructure-as-Code (IaC) approach to developing, containerizing, and deploying a minimal web service on Microsoft Azure using Terraform and GitHub Actions.

##🎯 Project Goal & OverviewThe **SimpleTimeService** is a small Flask microservice that returns the current timestamp and the visitor's true public IP address in a JSON format.

The entire deployment is automated and manages:

1. **Application Code:** Python Flask app.
2. **Containerization:** Docker image built to best practices (non-root user, small size).
3. **CI/CD:** GitHub Actions pipeline for automated image build/publish and infrastructure deployment.
4. **Infrastructure:** Azure Application Gateway, Container App Environment, Networking (VNet/Subnets), and Remote Terraform State Backend (Azure Storage).

The infrastructure follows a secure pattern: **Public Load Balancer (App Gateway) \rightarrow Internal Container App Environment \rightarrow SimpleTimeService Container.**

---

##🛠️ PrerequisitesTo successfully build and deploy this project, the following tools must be installed and configured on your machine:

| Tool | Purpose | Installation Link |
| --- | --- | --- |
| **Git** | Clone the repository. | [Git Installation](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) |
| **Docker** | Build and run the container locally. | [Docker Engine Installation](https://docs.docker.com/engine/install/) |
| **Terraform (v1.6+)** | Provision the Azure infrastructure. | [Terraform Installation](https://developer.hashicorp.com/terraform/downloads) |
| **Azure CLI (AZ)** | Authenticate and manage Azure resources. | [Azure CLI Installation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) |

###Cloud Credentials Setup (Mandatory)You must authenticate the Azure CLI before running any local Terraform commands:

```bash
# Log in interactively to your Azure account
az login

# Set the correct subscription where you want to deploy
# Replace <SUBSCRIPTION_ID> with your target ID
az account set --subscription "<SUBSCRIPTION_ID>"

```

---

##☁️ Task 1: Application and ContainerThe application code is located in the `app/` directory.

###1. SimpleTimeService (`app/app.py`)The Flask application is configured to correctly extract the visitor's public IP address (X.X.X.X) when running behind a proxy like the Azure Application Gateway.

**Expected JSON Output:**

```json
{
  "timestamp": "YYYY-MM-DDTHH:MM:SS.XXXXXX", 
  "ip": "X.X.X.X"
}

```

###2. Local Container Build and RunYou can test the application locally using the pre-built image from the public registry.

**Pull and Run the Pre-built Image:**
The CI/CD pipeline publishes the image to: `particle41.azurecr.io/particle41:latest`.

```bash
# 1. Pull the image
docker pull particle41.azurecr.io/particle41:latest

# 2. Run the container, mapping the container port (8080) to the host port (8080)
# Note: The Dockerfile runs the application as a non-root user.
docker run -d -p 8080:8080 --name simple-time-service particle41.azurecr.io/particle41:latest

# 3. Test the service (expected to return the local machine's IP, e.g., "172.17.0.1")
curl http://localhost:8080

# 4. Clean up
docker stop simple-time-service
docker rm simple-time-service

```

---

##🏗️ Task 2 & Extra Credit: Infrastructure DeploymentThe infrastructure setup is split into two Terraform root modules for clean separation:

1. **`terraform-backend/`**: Creates the remote state storage (Extra Credit).
2. **`terraform-infra/`**: Deploys the application and networking.

###Phase A: Setup Remote Terraform Backend**Purpose:** Creates the Azure Storage Account and Container to store the `terraform.tfstate` file, ensuring state locking and collaboration capabilities.

1. Navigate to the backend directory:
```bash
cd terraform-backend/

```


2. Initialize and deploy the backend resources:
```bash
terraform init
terraform apply -auto-approve

```



###Phase B: Deploy Core InfrastructureThis step deploys the VNet, Subnets, Container App Environment, Log Analytics Workspace, Public IP, Application Gateway, and the Container App itself.

1. **Update State Configuration:** After the backend is created, you must update the `backend.tf` file inside the **`terraform-infra/`** directory with the names of the resources created in Phase A.
* *Note: If you plan to use the GitHub Actions pipeline, this update is essential for local runs, but the CI/CD pipeline handles the state mapping automatically.*


2. Navigate to the infrastructure directory:
```bash
cd ../terraform-infra/

```


3. Initialize Terraform (will connect to the remote backend):
```bash
terraform init

```


4. Review the execution plan:
```bash
terraform plan

```


5. Deploy the infrastructure and application:
```bash
terraform apply -auto-approve

```



###Post-Deployment & VerificationAfter `terraform apply` completes successfully, it will output the Application Gateway's public URL.

**To Verify the Deployment:**

1. Copy the output URL:
```bash
terraform output app_gateway_url

```


2. Open the URL in your browser or use `curl`.
* **Expected Result:** A JSON response where the `ip` field is your true public IP address (the visitor's IP), demonstrating the correct configuration of the Application Gateway and Container App.



---

##⚙️ Extra Credit: CI/CD Pipeline (GitHub Actions)This repository includes a full CI/CD pipeline defined in the `.github/workflows/` directory.

| Workflow File | Purpose | Trigger |
| --- | --- | --- |
| `docker-build.yml` | **Build & Push:** Triggers on pushes to `main`. Builds the Docker image from `app/Dockerfile` and pushes it to `particle41.azurecr.io/particle41:latest`. | Push to `main` (for `app/` changes) |
| `terraform.yml` | **Plan & Apply:** Triggers on PRs/pushes to `main`. Executes `terraform plan` on PRs and `terraform apply` on merges to `main`. | Push/PR to `main` (for `terraform-infra/` changes only) |

###Authentication for CI/CDThe `terraform.yml` workflow authenticates to Azure using a dedicated Service Principal with **Contributor** access at the **Subscription** scope. The credentials (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, etc.) are stored securely as **GitHub Secrets**.

###Triggering the Deployment* **For Infrastructure Changes:** Push a change to any file within the `terraform-infra/` directory.
* **For Application Changes:** Push a change to any file within the `app/` directory (requires manual update of the image tag in `terraform-infra/variables.tf` to pull the new version, or a more advanced pipeline integration).

---

##🗑️ Cleanup (MANDATORY)To avoid recurring cloud costs, remember to destroy all resources you created.

1. Navigate to the infrastructure directory:
```bash
cd terraform-infra/

```


2. Destroy the core infrastructure:
```bash
terraform destroy -auto-approve

```


3. Navigate to the backend directory:
```bash
cd ../terraform-backend/

```


4. Destroy the remote state backend resources (Storage Account and Resource Group):
```bash
terraform destroy -auto-approve

```


* *Note: If the state file is not cleared from the storage container, the final destroy may fail. If this happens, delete the blob manually in the Azure Portal.*