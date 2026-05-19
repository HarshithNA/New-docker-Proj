pipeline {
    agent any

    environment {
        AWS_REGION   = 'eu-north-1'
        ECR_REGISTRY = '710119226111.dkr.ecr.eu-north-1.amazonaws.com'
        ECR_REPO     = 'my-app'
        IMAGE        = "${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}"
        DEPLOY_HOST  = 'ubuntu@13.60.27.114'
        CONTAINER    = 'my-app'
        APP_PORT     = '8080'
    }

    tools {
        // Name must match exactly what you set in:
        // Manage Jenkins → Global Tool Configuration → SonarQube Scanner
        'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarScanner'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/HarshithNA/New-docker-Proj',
                    credentialsId: 'git-credentials'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "${tool('SonarScanner')}/bin/sonar-scanner -Dsonar.projectKey=${ECR_REPO} -Dsonar.sources=."
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE} ."
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                      docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    docker push ${IMAGE}
                    docker rmi ${IMAGE}
                """
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['deploy-server-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_HOST} \
                          "aws ecr get-login-password --region ${AWS_REGION} | \
                             docker login --username AWS --password-stdin ${ECR_REGISTRY} && \
                           docker pull ${IMAGE} && \
                           docker stop ${CONTAINER} 2>/dev/null || true && \
                           docker rm   ${CONTAINER} 2>/dev/null || true && \
                           docker run -d --name ${CONTAINER} --restart unless-stopped \
                             -p ${APP_PORT}:${APP_PORT} ${IMAGE}"
                    """
                }
            }
        }
    }

    post {
        success { echo "Build #${BUILD_NUMBER} deployed successfully" }
        failure { echo "Build #${BUILD_NUMBER} failed" }
        always  { cleanWs() }
    }
}
