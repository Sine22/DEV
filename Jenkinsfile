pipeline {
    agent any

    stages {
        stage('Prepare') {
            steps {
                nodejs(nodeJSInstallationName: 'NodeJS 24') {
                    sh "npm ci"
                }
            }
        }
        stage('Test') {
            steps {
                nodejs(nodeJSInstallationName: 'NodeJS 24') {
                    sh "npm run test"
                }
            }
        }
		  stage('Push Registry') {
		      steps {
                sh 'docker build . --tag ttl.sh/app_aung:1h'
                sh 'docker push ttl.sh/app_aung:1h'
            }
		  }
		  stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: 'k8key', serverUrl: 'https://kubernetes:6443']) {
                    sh 'kubectl apply -f pod.yaml'
                }
            }
        }
    }
}
