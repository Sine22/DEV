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
        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'target_key', keyFileVariable: 'FILENAME', usernameVariable: 'USERNAME')]) {
                    sh '''
                        set -e
                        mkdir -p /home/laborant/app
                        cp index.js package.json package-lock.json /home/laborant/app/
                        chmod 755 /home/laborant/app/index.js
                        cd /home/laborant/app && npm ci
                        sudo cp myapp.service /etc/systemd/system/myapp.service
                        sudo systemctl daemon-reload
                        sudo systemctl enable myapp
                        sudo systemctl restart myapp
                                                      '''
                    sh '''
                        sudo systemctl restart docker
                        docker stop app_sine || true
                        docker rm app_sine || true
                        docker run -d --restart always -p 4444:4444 --name app_sine ttl.sh/app_sine:1h'''
                }
            }
        }
    }
}
