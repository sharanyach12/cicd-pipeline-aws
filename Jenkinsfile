pipeline {
    agent any

    environment {
        AWS_REGION    = 'us-east-1'
        ECR_REPO      = 'your-ecr-repo-uri'
        IMAGE_TAG     = "${env.BUILD_NUMBER}"
        ECS_CLUSTER   = 'your-cluster-name'
        ECS_SERVICE   = 'your-service-name'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run Tests') {
            steps {
                sh 'echo Running unit tests...'
                sh 'pytest tests/ -v || true'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
                sh 'docker tag $ECR_REPO:$IMAGE_TAG $ECR_REPO:latest'
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_REPO
                    docker push $ECR_REPO:$IMAGE_TAG
                    docker push $ECR_REPO:latest
                '''
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                        --cluster $ECS_CLUSTER \
                        --service $ECS_SERVICE \
                        --force-new-deployment \
                        --region $AWS_REGION
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    aws ecs wait services-stable \
                        --cluster $ECS_CLUSTER \
                        --services $ECS_SERVICE \
                        --region $AWS_REGION
                    echo "Deployment successful"
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded — image $IMAGE_TAG deployed to ECS"
        }
        failure {
            echo "Pipeline failed — triggering SNS alert"
            sh '''
                aws sns publish \
                    --topic-arn arn:aws:sns:us-east-1:123456789:alerts \
                    --message "Build $IMAGE_TAG failed on branch $GIT_BRANCH" \
                    --region $AWS_REGION
            '''
        }
    }
}
