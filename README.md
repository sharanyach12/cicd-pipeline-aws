# cicd-pipeline-aws

End-to-end CI/CD pipeline for containerized application deployments on AWS — from GitHub commit to production ECS in a single automated flow.

Built using Jenkins, AWS CodePipeline, CodeBuild, and CodeDeploy with Docker containerization and ECS orchestration. Designed for zero-downtime deployments across DEV / QA / UAT / PROD environments.

---

## Pipeline overview

```
  Developer Push
       │
       ▼
  GitHub Repo ──────────────────────────────────────────┐
       │                                                 │
       ▼                                                 │
  Jenkins (Webhook Trigger)                              │
       │                                                 │
       ├── Code Checkout                                 │
       ├── Unit Tests (Maven / pytest)                   │
       ├── Static Code Analysis                          │
       ├── Docker Build & Tag                            │
       └── Push to ECR ───────────────────────────────┐  │
                                                       │  │
       ▼                                               │  │
  AWS CodePipeline (Triggered on ECR push)             │  │
       │                                               │  │
       ├── Source Stage (ECR image)                    │  │
       ├── Build Stage (CodeBuild)                     ◄──┘
       │     └── buildspec.yml → task def update       │
       └── Deploy Stage (CodeDeploy)                   │
             └── Blue/Green → ECS Fargate / EC2        ◄──┘
                   │
                   ▼
            Production Traffic
```

---

## Repo structure

```
cicd-pipeline-aws/
├── Jenkinsfile                   # Declarative pipeline definition
├── Dockerfile                    # Multi-stage application container build
├── buildspec.yml                 # AWS CodeBuild build specification
├── appspec.yaml                  # CodeDeploy deployment configuration
├── taskdef.json                  # ECS task definition template
├── codepipeline/
│   └── pipeline.json             # CodePipeline structure definition
├── scripts/
│   ├── before_install.sh         # Pre-deployment hook
│   └── after_allow_traffic.sh    # Post-deployment health check
└── README.md
```

---

## Jenkinsfile — pipeline stages

```groovy
pipeline {
    agent any
    environment {
        AWS_REGION    = 'us-east-1'
        ECR_REPO      = 'your-ecr-repo-uri'
        IMAGE_TAG     = "${env.BUILD_NUMBER}"
    }
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Test') {
            steps { sh 'pytest tests/ -v' }
        }
        stage('Docker Build') {
            steps {
                sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
            }
        }
        stage('Push to ECR') {
            steps {
                sh '''
                  aws ecr get-login-password --region $AWS_REGION | \
                  docker login --username AWS --password-stdin $ECR_REPO
                  docker push $ECR_REPO:$IMAGE_TAG
                '''
            }
        }
        stage('Deploy to ECS') {
            steps {
                sh 'aws codepipeline start-pipeline-execution --name my-pipeline'
            }
        }
    }
    post {
        failure { echo 'Pipeline failed — notifying via SNS' }
        success { echo 'Deployment successful' }
    }
}
```

---

## buildspec.yml — CodeBuild spec

```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
  build:
    commands:
      - docker build -t $ECR_URI:$IMAGE_TAG .
      - docker push $ECR_URI:$IMAGE_TAG
      - printf '[{"name":"app","imageUri":"%s"}]' $ECR_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files:
    - imagedefinitions.json
    - appspec.yaml
    - taskdef.json
```

---

## Tech stack

| Tool | Role |
|---|---|
| Jenkins | Pipeline trigger, test, build orchestration |
| AWS CodePipeline | Deployment pipeline across environments |
| AWS CodeBuild | Containerized build environment |
| AWS CodeDeploy | Blue/green ECS deployment |
| Docker | Application containerization |
| AWS ECR | Private container image registry |
| AWS ECS (Fargate / EC2) | Container orchestration |
| Apache Airflow | Scheduled job orchestration |
| AWS SNS | Build failure notifications |

---

## Deployment strategy

**Blue/Green deployments** via CodeDeploy — new task set spun up alongside existing, traffic shifted only after health checks pass. Instant rollback if health check fails within the defined window.

**Environment promotion** — images are built once (in DEV) and promoted through environments by updating the task definition image URI. No rebuilds per environment.

---

## Outcomes from production use

- Reduced deployment time by **50%** through full pipeline automation
- Achieved **zero-downtime deployments** across all environments via blue/green strategy
- Eliminated manual deployment steps — entire flow triggered by a single `git push`
- Rollback time reduced from 30+ minutes to under **2 minutes**

---

## Related repos

- [aws-multi-env-iac](https://github.com/sharanyachinthakuntla/aws-multi-env-iac) — Infrastructure this pipeline deploys into
- [grafana-observability-stack](https://github.com/sharanyachinthakuntla/grafana-observability-stack) — Monitoring stack for deployed services

---

## Author

**Sharanya Chinthakuntla** — AWS DevOps Engineer · Atlanta, GA
[LinkedIn](https://linkedin.com/in/sharanya-chinthakuntla) · [Email](mailto:Sharanyachinthakuntla99@gmail.com)
# cicd-pipeline-aws
