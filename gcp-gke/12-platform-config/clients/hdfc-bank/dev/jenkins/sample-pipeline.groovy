pipeline {
    agent {
        label 'docker-agent'
    }

    environment {
        IMAGE_REPO_NAME     = "testuser40/sample-flask-app"
        REGISTRY_CREDENTIAL = "dockerhub_id"
        GITHUB_CREDENTIAL   = "github-vedant-bari"
        
        GCP_PROJECT         = "eks-terraform"
        GCP_REGION          = "asia-south1"
        CLUSTER_NAME        = "gke-hdfc-bank-dev"
        K8S_NAMESPACE       = "backend-web-dev"
        DEPLOYMENT_NAME     = "backend-web-dev-generic-app"
        CONTAINER_NAME      = "generic-app"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Fetching code from GitHub repository'
                git branch: 'main', 
                    credentialsId: "${env.GITHUB_CREDENTIAL}", 
                    url: 'https://github.com/vedant-bari/flask-ci-cd.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        sh 'git config --global --add safe.directory $(pwd)'
                        def dockerTag = sh(label: '', returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        env.DOCKER_TAG = dockerTag
                        
                        sh "docker build . -t ${env.IMAGE_REPO_NAME}:${env.DOCKER_TAG}"
                        sh "docker tag ${env.IMAGE_REPO_NAME}:${env.DOCKER_TAG} ${env.IMAGE_REPO_NAME}:latest"
                    }
                }
            }
        }

        stage('Docker Hub Push') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(
                        credentialsId: "${env.REGISTRY_CREDENTIAL}",
                        passwordVariable: 'DOCKERHUB_PASSWORD',
                        usernameVariable: 'DOCKERHUB_USERNAME'
                    )]) {
                        sh 'docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"'
                        sh "docker push ${env.IMAGE_REPO_NAME}:${env.DOCKER_TAG}"
                        sh "docker push ${env.IMAGE_REPO_NAME}:latest"
                    }
                }
            }
        }

        stage('GKE Deploy') {
            steps {
                container('gcloud') {
                    script {
                        // Automatically install kubectl component in the Alpine gcloud container
                        sh 'gcloud components install kubectl --quiet || true'
                        
                        // Execute deployment update using native in-cluster service account context
                        sh "kubectl set image deployment/${env.DEPLOYMENT_NAME} ${env.CONTAINER_NAME}=${env.IMAGE_REPO_NAME}:${env.DOCKER_TAG} -n ${env.K8S_NAMESPACE}"
                    }
                }
            }
        }

        stage('Verify Rollout') {
            steps {
                container('gcloud') {
                    script {
                        sh "kubectl rollout status deployment/${env.DEPLOYMENT_NAME} --timeout=180s -n ${env.K8S_NAMESPACE}"
                    }
                }
            }
        }
    }
}