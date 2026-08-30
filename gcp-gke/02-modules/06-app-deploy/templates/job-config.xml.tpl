<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Managed via Terraform Blueprint &amp; Terragrunt</description>
  <keepDependencies>false</keepDependencies>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script>
pipeline {
    agent {
        label 'docker-agent'
    }

    environment {
        IMAGE_REPO_NAME     = "${image_repo}"
        REGISTRY_CREDENTIAL = "${dockerhub_credential}"
        GITHUB_CREDENTIAL   = "${github_credentials}"
        
        GCP_PROJECT         = "${gcp_project}"
        GCP_REGION          = "${gcp_region}"
        CLUSTER_NAME        = "${cluster_name}"
        K8S_NAMESPACE       = "${k8s_namespace}"
        DEPLOYMENT_NAME     = "${deployment_name}"
        CONTAINER_NAME      = "${container_name}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Fetching code from GitHub repository'
                git branch: '${branch}', 
                    credentialsId: "$${env.GITHUB_CREDENTIAL}", 
                    url: '${git_url}'
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        sh 'git config --global --add safe.directory $(pwd)'
                        def dockerTag = sh(label: '', returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        env.DOCKER_TAG = dockerTag
                        
                        sh "docker build . -t $${env.IMAGE_REPO_NAME}:$${env.DOCKER_TAG}"
                        sh "docker tag $${env.IMAGE_REPO_NAME}:$${env.DOCKER_TAG} $${env.IMAGE_REPO_NAME}:latest"
                    }
                }
            }
        }

        stage('Docker Hub Push') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(
                        credentialsId: "$${env.REGISTRY_CREDENTIAL}",
                        passwordVariable: 'DOCKERHUB_PASSWORD',
                        usernameVariable: 'DOCKERHUB_USERNAME'
                    )]) {
                        sh 'docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"'
                        sh "docker push $${env.IMAGE_REPO_NAME}:$${env.DOCKER_TAG}"
                        sh "docker push $${env.IMAGE_REPO_NAME}:latest"
                    }
                }
            }
        }

        stage('GKE Deploy') {
            steps {
                container('gcloud') {
                    script {
                         // Automatically install kubectl component in the Alpine gcloud container
                        sh "gcloud components install kubectl --quiet || true"
                        sh "kubectl set image deployment/$${env.DEPLOYMENT_NAME} $${env.CONTAINER_NAME}=$${env.IMAGE_REPO_NAME}:$${env.DOCKER_TAG} -n $${env.K8S_NAMESPACE}"
                    }
                }
            }
        }

        stage('Verify Rollout') {
            steps {
                container('gcloud') {
                    script {
                        sh "kubectl rollout status deployment/$${env.DEPLOYMENT_NAME} --timeout=300s -n $${env.K8S_NAMESPACE}"
                    }
                }
            }
        }
    }
}
    </script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>