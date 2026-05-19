pipeline {
    agent any

    environment {
        AWS_REGION     = 'us-east-1'
        ECR_REGISTRY   = '503884896971.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO       = 'my-application'
        IMAGE          = "${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}"
        DEPLOY_HOST    = 'ubuntu@172.31.13.116'
        CONTAINER      = 'my-application'
        APP_PORT       = '8080'
    }
    
    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "sonar-scanner -Dsonar.projectKey=${ECR_REPO} -Dsonar.sources=src"
                }
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
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_HOST} '
                          aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REGISTRY}
                          docker pull ${IMAGE}
                          docker stop ${CONTAINER} 2>/dev/null || true
                          docker rm   ${CONTAINER} 2>/dev/null || true
                          docker run -d --name ${CONTAINER} --restart unless-stopped \
                            -p ${APP_PORT}:${APP_PORT} ${IMAGE}
                        '
                    """
                }
            }
        }
    }

    post {
        success { echo "✅ Build #${BUILD_NUMBER} deployed successfully" }
        failure { echo "❌ Build #${BUILD_NUMBER} failed" }
        always  { cleanWs() }
    }

