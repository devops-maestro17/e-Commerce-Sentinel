# DevSecOps Project to setup Amazon clone on AWS using CICD, Security, Monitoring and GitOps

## Overview
The project involved the implementation of a comprehensive CI/CD pipeline for deploying an Amazon clone application to an Elastic Kubernetes Service (EKS) cluster, following DevSecOps best practices. The infrastructure was provisioned using Terraform, and Jenkins was utilized as the Continuous Integration (CI) tool.

In the CI stage, several security and quality checks were performed, including:

- Static code analysis using SonarQube to identify code quality issues and vulnerabilities.
- OWASP dependency check to scan for known vulnerabilities in third-party dependencies.
- File scan using Trivy to detect vulnerabilities in application files.
- Building a Docker image and scanning it with Trivy to identify vulnerabilities in the container image.

After successful completion of the security checks, the Docker image was pushed to Docker Hub. Shell scripts were employed to update the Kubernetes manifests with the latest image tag.

The Continuous Deployment (CD) stage leveraged ArgoCD, a declarative continuous delivery tool, to automatically deploy the updated application to the EKS cluster. ArgoCD monitors the specified Git repository for changes and applies the updated manifests to the target EKS cluster.

Additionally, monitoring and observability were established using Prometheus and Grafana. Prometheus was configured to collect metrics from both the Jenkins server and the EKS clusters, enabling the identification of potential performance bottlenecks through Grafana visualizations.

## Prerequisites
Before proceeding, ensure to have an AWS account where we will be performing all the setup and configuration and it might incur some costs.

## Installing Terraform on AWS CloudShell
In this project, Terraform is used to create the servers for Jenkins and SonarQube and install the required tools. To install Terraform, activate the AWS CloudShell and follow the below steps:

```bash
# Install Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# Verify the installation
terraform -help
```

<img width="532" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/085e9db0-16d2-43fb-a83c-9c352ee84676">

### Clone the repository
Clone the git repository and navigate to the `terraform-scripts` folder to create the infrastructure

```bash
git clone https://github.com/devops-maestro17/e-Commerce-Sentinel.git
cd e-Commerce-Sentinel/terraform-scripts/
```
The `main.tf` file contains the code to create the resources. It uses variables to avoid hardcoded values. Inside the `terraform.tfvars`, the variables for AMI ID, instance types and volume size are initialized which can be used while applying the configuration. 

```bash
# terraform.tfvars
ami = "ami-007020fd9c84e18c7"
instance_type_1 = "t2.large"
instance_type_2 = "t2.medium"
volume_size_1 = 30
volume_size_2 = 10
```

The folder also contains `install-jenkins.sh` and `install-sonarqube.sh` scripts to install Jenkins, Trivy and SonarQube on the servers 

#### install-jenkins.sh
```bash
#!/bin/bash
# Install Docker
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo chmod 777 /var/run/docker.sock

# Install Jenkins
sudo apt update
sudo apt install fontconfig openjdk-17-jre -y
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins -y

# Install Trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy
```

### install-sonarqube.sh
```bash
#!/bin/bash

# Install Docker
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Install Sonarqube
sudo chmod 777 /var/run/docker.sock
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
```

