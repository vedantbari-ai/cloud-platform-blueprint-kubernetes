pipeline {
    agent {
        label 'docker-agent'
    }
    stages {
        stage('Test Docker-in-Docker Agent') {
            steps {
                container('docker') {
                    sh 'docker version'
                    sh 'docker info'
                    echo 'Docker daemon connection established successfully inside the sidecar!'
                }
            }
        }
    }
}