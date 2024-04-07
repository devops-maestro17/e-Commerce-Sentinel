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
- OWASP Dependency Check
- Docker
- Docker commons
- Docker Pipeline
- Docker API
- Prometheus metrics

<img width="959" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/b93ff47b-ab59-42a7-8372-1c2b44ab7b4d">



## Configuring the Tools in Jenkins
Navigate to  Manage Jenkins -> Tools and install JDK, NodeJS, SonarQube scanner, Docker and OWASP by referring to the following screenshots

#### JDK17
<img width="922" alt="jdk-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/194a1c07-c243-4568-9fa4-ff7c0be03855">


### NodeJS
<img width="932" alt="nodejs-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/400c6b73-3707-47a4-9deb-909b1c7f130f">


### SonarQube Scanner
<img width="872" alt="sonar-scanner-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/329a5f90-743e-42eb-af27-0685dbe7a397">


### Docker
<img width="896" alt="docker-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/2cc12960-3459-4ada-b9e0-efe6f844ad51">


### OWASP
<img width="896" alt="owasp-tool-install" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/47535d11-aa2e-40c1-978d-51ac5e8fc179">


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



## Adding DockerHub credentials in Jenkins
Go to Dashboard -> Manage Jenkins -> Credentials -> System -> Global credentials (unrestricted) -> Add Credentials -> Username with password and provide the DockerHub credentials with the ID as `docker`

<img width="816" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/1d94b04c-0563-49ff-8f8b-376484120115">



## Setting up the CI pipeline

Go to Jenkins dashboard and create a New Pipeline.

<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/696fb7b5-c35f-461c-b70c-4a353681b1bb">




<img width="960" alt="image" src="https://github.com/devops-maestro17/e-Commerce-Sentinel/assets/148553140/09e59e4f-38cb-4cbe-87d6-f10201ce2cbe">


The steps for the pipeline are present in the JenkinsFile. The file contains the pipeline configuration as shown below:

```bash
pipeline{
    agent any
    tools{
        jdk 'jdk17'
        nodejs 'nodejs16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('Clean Workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/devops-maestro17/e-Commerce-Sentinel.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=AmazonClone \
                    -Dsonar.projectKey=AmazonClone '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('TRIVY File System Scan') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh "docker build -t amazon-clone ."
                       sh "docker tag amazon containerizeops/amazon-clone:latest "
                       sh "docker push containerizeops/amazon-clone:latest "
                    }
                }
            }
        }
        stage("TRIVY Image Scan"){
            steps{
                sh "trivy image containerizeops/amazon-clone:latest > trivyimage.txt"
            }
        }
    }
}
```











