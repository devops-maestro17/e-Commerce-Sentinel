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
        // stage("Sonarqube Analysis "){
        //     steps{
        //         withSonarQubeEnv('sonar-server') {
        //             sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=AmazonClone \
        //             -Dsonar.projectKey=AmazonClone '''
        //         }
        //     }
        // }
        // stage("quality gate"){
        //    steps {
        //         script {
        //             waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
        //         }
        //     }
        // }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey 9452d758-d7654e59-a36c-7f2dc3c5d230' , odcInstallation: 'DP-Check'
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
