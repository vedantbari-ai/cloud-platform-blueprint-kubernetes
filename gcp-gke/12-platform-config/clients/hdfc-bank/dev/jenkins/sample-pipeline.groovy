pipeline {
    agent {
        label 'docker-agent'
    }

    stages {
        stage('Test Docker') {
            steps {
                container('docker') {
                    sh '''
                        echo "DOCKER_HOST=$DOCKER_HOST"
                        docker version
                        docker info
                        docker run --rm hello-world
                    '''
                }
            }
        }
    }
}