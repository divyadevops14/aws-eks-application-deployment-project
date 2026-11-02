pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        AWS_REGION     = 'us-east-1'
        AWS_ACCOUNT_ID = '131696162455'
        ECR_REPOSITORY = 'eks-demo-app'
        EKS_CLUSTER    = 'eks-demo'
        K8S_NAMESPACE  = 'default'
        DEPLOYMENT     = 'eks-demo-app'
        CONTAINER_NAME = 'eks-demo-app'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_URI    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Downloading source code from GitHub'
                git branch: 'main',
                    url: 'https://github.com/divyadevops14/aws-eks-application-deployment.git'
            }
        }

        // NOTE: a Jenkins bat step only fails if the LAST command fails.
        // Every command below ends with "|| exit /b 1" so any failure stops the stage.

        stage('Validate') {
            steps {
                echo 'Checking project files and tools'
                bat '''
                    if not exist app\\Dockerfile (
                        echo Dockerfile not found
                        exit /b 1
                    )
                    if not exist app\\server.js (
                        echo Application file not found
                        exit /b 1
                    )
                    docker --version || exit /b 1
                    aws --version || exit /b 1
                    kubectl version --client || exit /b 1
                '''
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image'
                bat '''
                    docker build -t %IMAGE_URI% -f app\\Dockerfile app || exit /b 1
                '''
            }
        }

        stage('ECR Login and Push') {
            steps {
                echo 'Authenticating with Amazon ECR and pushing the image'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    bat '''
                        aws sts get-caller-identity || exit /b 1
                        aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REGISTRY% || exit /b 1
                        docker push %IMAGE_URI% || exit /b 1
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo 'Deploying application to Amazon EKS'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    bat '''
                        aws eks update-kubeconfig --region %AWS_REGION% --name %EKS_CLUSTER% || exit /b 1
                        kubectl set image deployment/%DEPLOYMENT% %CONTAINER_NAME%=%IMAGE_URI% -n %K8S_NAMESPACE% || exit /b 1
                        kubectl rollout status deployment/%DEPLOYMENT% -n %K8S_NAMESPACE% --timeout=180s || exit /b 1
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying application deployment'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    bat '''
                        kubectl get pods -n %K8S_NAMESPACE% || exit /b 1
                        kubectl get svc -n %K8S_NAMESPACE% || exit /b 1
                        kubectl get ingress -n %K8S_NAMESPACE% || exit /b 1
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS: ${IMAGE_URI} deployed to AWS EKS!"
        }
        failure {
            echo 'FAILED: Check the Jenkins console output for errors.'
        }
        always {
            echo 'Jenkins pipeline execution completed.'
        }
    }
}
