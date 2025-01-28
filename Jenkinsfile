
pipeline{
    agent any
    
    tools{
        jdk 'jdk17'
        nodejs 'nodejs16'
        snyk 'snyk'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        SNYK_TOKEN = credentials('snyk-token')
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
        
        stage("Sonarqube Scan "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=AmazonClone \
                    -Dsonar.projectKey=AmazonClone '''
                }
            }
        }
        
        stage("Quality Gate Analysis"){
          steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }

        stage('Dependencies') {
            parallel {
                stage('Install Dependencies') {
                    steps {
                        sh "npm install"
                    }
                }
                stage('Snyk CLI Install'){
                    steps{
                        sh 'npm install -g snyk'
                    }
                }
            }
        }

        stage('Dependencies') {
            parallel {
                stage('Snyk Dependency Check'){
                    steps{
                        sh 'snyk test --severity-threshold=critical --fail-on=upgradable \
                        --json-file-output=dependency-check.json'
                    }
                }
                stage('Trivy File System Scan') {
                    steps {
                        sh "trivy fs . > trivy-file-scan-report.txt"
                    }
                }
            }
        }

        stage("Docker Build & Push"){
            steps{
                script{
                  withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                      sh "docker build -t amazon-clone ."
                      sh "docker tag amazon-clone containerizeops/amazon-clone:1.1 "
                      sh "docker push containerizeops/amazon-clone:1.1 "
                    }
                }
            }
        }
        
        stage("Trivy Image Scan"){
            steps{
                sh "trivy image containerizeops/amazon-clone:1.1 > trivy-image-report.txt"
            }
        }
        
        stage("Update Deployment manifest"){
            environment {
                GIT_REPO_NAME = "e-Commerce-Sentinel"
                GIT_USER_NAME = "devops-maestro17"
            }
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        git config user.email "rajdeep_deogharia@outlook.com"
                        git config user.name "devops-maestro17"
                        BUILD_NUMBER=${BUILD_NUMBER}
                        sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" k8s-manifests/deployment.yml
                        git add k8s-manifests/deployment.yml
                        git commit -m "Update deployment image to version ${BUILD_NUMBER}"
                        git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                def jobName = env.JOB_NAME
                def buildNumber = env.BUILD_NUMBER
                def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
                def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'
    
                def body = """
                    <html>
                    <body>
                    <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                    <h2>${jobName} - Build ${buildNumber}</h2>
                    <div style="background-color: ${bannerColor}; padding: 10px;">
                    <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                    </div>
                    <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
                    <p> Please find the attached reports: Snyk Vulnerability Report, Trivy File Scan Report, Trivy Image Scan Report </p>
                    </div>
                    </body>
                    </html>
                """
    
                emailext (
                    subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
                    body: body,
                    to: 'gcp.rajdeep@gmail.com',
                    from: 'jenkins@example.com',
                    replyTo: 'jenkins@example.com',
                    mimeType: 'text/html',
                    attachmentsPattern: 'dependency-check.json, trivy-file-scan-report.txt, trivy-image-report.txt'
                )
            }
        }
    }
}
