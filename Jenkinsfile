pipeline {
    agent any
    environment {
        AWS_REGION   = 'eu-north-1'
        ECR_REGISTRY = '710119226111.dkr.ecr.eu-north-1.amazonaws.com'
        ECR_REPO     = 'my-app'
        IMAGE        = "${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}"
        DEPLOY_HOST  = 'ubuntu@172.31.40.82'
        CONTAINER    = 'my-app'
        APP_PORT     = '8080'
    }
    tools {
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
        stage('Update Manifest & ArgoCD Sync') {
  steps {
    sh """
      
      sed -i 's|tag:.*|tag: "${BUILD_NUMBER}"|' \
        k8s/helm/values.yaml
      git add k8s/helm/values.yaml
      git commit -m "ci: deploy build ${BUILD_NUMBER}"
      git push origin main

      
      argocd app sync my-app \
        --server ${ARGO_SERVER} \
        --auth-token ${ARGO_TOKEN} \
        --grpc-web
      argocd app wait my-app --health
    """
  }
}
    }       
    post {
        success { echo "Build #${BUILD_NUMBER} deployed successfully" }
        failure { echo "Build #${BUILD_NUMBER} failed" }
        always  { cleanWs() }
    }
} 
