pipeline {
    agent any
    environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub')
                }
        stages {
            stage('Docker Stop, Remove, Build and Run') {
                agent any
            steps {
                sh 'if [ $(docker ps -aq) ]; then docker ps -aq | xargs docker stop;fi'
                sh 'docker system prune -af --volumes'
                sh 'docker build . -t lgandzii/orbit -f Dockerfile'
                sh 'kubectl run --name orbit -d -p 80:80 lgandzii/orbit'
                }
                                 }
            stage('Dockerhub') {
                agent any
                steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker push lgandzii/orbit:latest'
                }
                }
         }
}
