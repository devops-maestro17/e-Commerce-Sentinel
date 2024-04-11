# DevSecOps CI/CD Pipeline to setup Amazon clone on AWS

## Overview
The project involved the implementation of a comprehensive CI/CD pipeline for deploying an Amazon clone application to an Elastic Kubernetes Service (EKS) cluster, following DevSecOps best practices. The infrastructure was provisioned using Terraform, and Jenkins was utilized as the Continuous Integration (CI) tool.

In the CI stage, several security and quality checks were performed, including:

- Static code analysis using SonarQube to identify code quality issues and vulnerabilities.
- Snyk dependency check to scan for known vulnerabilities in third-party dependencies.
- File scan using Trivy to detect vulnerabilities in application files.
- Building a Docker image and scanning it with Trivy to identify vulnerabilities in the container image.

After successful completion of the security checks, the Docker image was pushed to Docker Hub. Shell scripts were employed to update the Kubernetes manifests with the latest image tag.

The Continuous Deployment (CD) stage leveraged ArgoCD, a declarative continuous delivery tool, to automatically deploy the updated application to the EKS cluster. ArgoCD monitors the specified Git repository for changes and applies the updated manifests to the target EKS cluster.

## Prerequisites
Before proceeding, ensure to have an AWS account where we will be performing all the setup and configuration and it might incur some costs. Also make sure to have a DockerHub account which will be used to host Docker images later in this project.

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

## Terraform setup

### Initialize Terraform
```bash
terraform init
```

### Review the execution plan
```bash
terraform plan
```

### Apply the Terraform configuration to create the required resources
```bash
terraform apply
# Enter "Yes" on the prompt
```

<img width="705" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/f00f0826-2a44-43b6-9d39-2d210ccef908">


Verify the creation of the servers by navigating to the EC2 instance section in AWS Console. Connect to the Jenkins server using EC2 Instance Connect feature

## Jenkins Setup
To verify whether jenkins is running:
```bash
sudo systemctl status jenkins
```
<img width="932" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/a850c3f0-4a04-41ff-b696-80452cd1b357">


By default, Jenkins can be accessed on port 8080, so copy the instance IP address and hit the URL `http://<ip-address>:<port>` to open Jenkins.
To fetch the Jenkins password, run the below command in Jenkins server:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Enter the password and then click in "Install suggested plugins"

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/64850be4-20cd-49c5-8be1-1b1b06f24222">


Create an user, provide all the details and the Jenkins dashboard will show up like this

<img width="957" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/582e10be-c419-4785-b90a-90ab6dd4a663">


## Install Plugins for the CI/CD Pipeline
Go to Manage Jenkins -> Plugins -> Available Plugins

And, install the below plugins
- Eclipse Temurin Installer
- SonarQube Scanner
- NodeJs Plugin
- Email Extension Template
- Snyk
- Docker
- Docker commons
- Docker Pipeline
- Docker API
- Prometheus metrics
- Blue Ocean

<img width="959" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/b93ff47b-ab59-42a7-8372-1c2b44ab7b4d">



## Configuring the Tools in Jenkins

Navigate to  Manage Jenkins -> Tools and install JDK, NodeJS, SonarQube scanner, Docker and Snyk by referring to the following screenshots

#### JDK17
<img width="922" alt="jdk-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/194a1c07-c243-4568-9fa4-ff7c0be03855">


### NodeJS
<img width="932" alt="nodejs-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/400c6b73-3707-47a4-9deb-909b1c7f130f">


### SonarQube Scanner
<img width="872" alt="sonar-scanner-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/329a5f90-743e-42eb-af27-0685dbe7a397">


### Docker
<img width="896" alt="docker-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/2cc12960-3459-4ada-b9e0-efe6f844ad51">


### Snyk
![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/5307bdbd-8e1b-4fdb-832c-55d9b50df095)


## SonarQube Setup

Connect to the SonarQube server by using EC2 instance connect and run the below command to verify sonarqube is running or not

```bash
docker ps
```

<img width="918" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/9c5db047-2d8d-42ed-b8a3-75f6f1004e7f">


Now, navigate to the URL `http:<public-ip-address-of-sonarqube-server>:9000` to access the SonarQube dashboard. Login by providing username: `admin` and password: `admin` and on the next window, provide a new password

<img width="959" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/0913f34a-e0f2-46f6-b06c-a19aaa4b4597">



Now goto Sonarqube Server. Click on Administration -> Security -> Users -> Click on Tokens and Update Token -> Give it a name -> and click on Generate Token

<img width="959" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/27216c90-ba8d-421d-b62d-380222ae410d">


<img width="955" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/8cb778ca-7994-4688-9b31-c510076d7ad2">



Copy the token and go to Jenkins Dashboard -> Manage Jenkins -> Credentials -> System -> Global credentials(unrestricted) -> Add Credential -> Secret Text. Paste the token and put the ID as `sonar-token` and click on Save

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/b5e0a8ea-4648-4d1d-aa5f-db766ac5c6fa">



Now go to Jenkins Dashboard → Manage Jenkins → System -> Add SonarQube and add the SonarQube server as shown below:

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/7daae398-5e35-4f39-81d2-70e37ef70b7b">



Click on Apply and Save

### Adding WebHook in SonarQube for Quality Gate configuration

In the SonarQube dashboard, navigate to Administration –> Configuration –> Webhooks -> Click on Create and provide the below details:

- Name: `jenkins `
- URL: `<http://jenkins-public-ip:8080>/sonarqube-webhook/`

Click on Create. This will create a webhook to notify Jenkins once the sonarqube analysis is completed.

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/f8590615-75a7-4b0c-a3bc-d2145c8dc90c">



## Adding DockerHub, Snyk and GitHub credentials in Jenkins

Go to Dashboard -> Manage Jenkins -> Credentials -> System -> Global credentials (unrestricted) -> Add Credentials -> Username with password and provide the DockerHub credentials with the ID as `docker`

<img width="816" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/1d94b04c-0563-49ff-8f8b-376484120115">


In order to add GitHub credentials, create a Personal Access Token by navigating to Github Settings -> Developer Settings -> Personal Access Tokens -> Tokens (Classic) -> Generate New Token. Create a new token and provide Repo Access permissions.

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/59c2371b-7592-470b-9f18-7dc94da735b9)



To add Snyk authentication token, create an account in Snyk by navigating to https://app.snyk.io. Navigate to Account Settings and generate a new Auth Token so that Jenkins can use this token to communicate with Snyk.

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/f349709e-302d-4ac5-90f0-cde9b635106d)



Now go to Jenkins Global Credentials, add the Github credential with the ID as `github-token` and Snyk token with the ID as `snyk-token` both in the form of Secret Text.

## Setting up Email Notification in Jenkins

To set up Email Notification in Jenkins setup a Gmail account and store the App Password securely as it will be used to authenticate with Jenkins. 
Navigate to Manage Jenkins -> System -> Extended Email Notification and provide the following details:
- SMTP Server: `smtp.gmail.com`
- SMTP Port: 465
- Under Advanced section, provide the Gmail credentials (email & App password) as shown below and enable `Use SSL` option

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/f8bfa4b6-a474-4d52-916e-34caea760b8b)



![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/752e892f-ed0f-4994-8cb3-c2677c62377e)


Provide the username and app password details again in the Email Notification section and enable `Use SSL` option

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/97d66341-4bd8-4d3c-830e-c7eb942a914d)


## Setting up the CI pipeline

Go to Jenkins dashboard and create a New Pipeline. In the Pipeline Configuration, choose the Pipeline Defintion as `Pipeline Script from SCM`, SCM as `Git`, provide the Repository URL, set the Branch Specifier as `main` and click on Save.

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/696fb7b5-c35f-461c-b70c-4a353681b1bb">




<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/09e59e4f-38cb-4cbe-87d6-f10201ce2cbe">




Go to Blue Ocean from Jenkins Dashboard and Run the pipeline. The final CI pipeline looks as follows:

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/f9ce1b33-5754-44a5-82b8-a7833e440d59)


Mail Notification:

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/38cbb7da-98fa-402f-b5c0-cd6c52eb43d1)



SonarQube Report:

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/1490c29e-c052-4669-b5fe-dd83bab20e54)




Snyk Dependency Check Report:

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/5ef9de11-c32d-4143-a45c-4f1e0d829e46)




Trivy File Scan Report:

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/cd56b762-984f-45bf-82c0-201990641866)




Trivy Image Scan Report:

![image](https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/824d9dec-1cf2-4ce9-9585-a1ce3534957a)



## Creating EKS cluster

To create an EKS cluster, use the below commands in CloudShell

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

Verify the installation by using
```bash
eksctl version
```


<img width="829" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/47662b8a-44db-438b-bf54-b1411975f6e2">



Create the cluster by using the below command
```bash
eksctl create cluster --name=my-cluster --region=ap-south-1 --zones=ap-south-1a,ap-south-1b --node-type=t3.medium --nodes=3
```


<img width="935" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/ea97c01e-bd15-43f1-8171-c061268d5fca">



## Install ArgoCD in the EKS cluster

Once the cluster is created, it's time to set up ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Check whether the ArgoCD pods are up by using `kubectl get pods -n argocd`

<img width="539" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/8499da62-c3cf-4d0e-a4c9-d0d428f66897">


Now change the service type of the ArgoCD Server to Load Balancer by using the below command

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

To verify whether the service type has changed, use `kubectl get svc -n argocd`

<img width="928" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/94557e6e-e3be-47ba-b0d7-e378b65b1656">



Now hit the Load Balancer IP address in a new tab to access the ArgoCD UI.

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/5bca167c-6a22-4f1d-8c1d-b5bf3796ba23">




To fetch the ArgoCD password, copy the value from `data.password` by running the below command

```bash
kubectl edit secret argocd-initial-admin-secret -n argocd
```

Now to decode the password, use

```bash
echo <password> | base64 --decode
```

Enter the username as `admin` and the password to enter the ArgoCD dashboard

## Create an ArgoCD Application

To create an ArgoCD application, click on New App > Edit as YAML and paste the below code. (This can also be created using kubectl apply command but we need to install ArgoCD CLI)

```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: amazon-clone-app
spec:
  destination:
    namespace: dev
    server: 'https://kubernetes.default.svc'
  source:
    path: k8s-manifests
    repoURL: 'https://github.com/devops-maestro17/e-Commerce-Sentinel.git'
    targetRevision: HEAD
  sources: []
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Click on Save > Create. This should start deploying the Amazon-Clone application to the Kubernetes (EKS) cluster

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/6db191a9-f2c7-4c21-ae26-9bf465f6e28c">



To verify whether the pods and services are running, use `kubectl get all -n dev`

<img width="853" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/1308ebae-f542-4d10-b690-0a67fb088cf6">



Fetch the Load balancer IP address to access the Amazon Clone application

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/8542fc27-66fa-49a6-bf40-991799b2be76">

