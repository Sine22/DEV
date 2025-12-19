pipeline {
    agent any

    tools {
        nodejs "node24"   // Jenkins NodeJS tool
    }

    environment {
        APP  = "myapp"
        IMG  = "ttl.sh/myapp:2h"
        PORT = "4444"
        NS   = "production"
        KUBE = "https://kubernetes:6443"
    }

    stages {

        stage('Test') {
            steps {
                sh '''
                  npm install
                  node --test
                '''
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                sh '''
                  docker build -t ${IMG} .
                  docker push ${IMG}
                '''
            }
        }

        stage('Deploy to Target VM') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'mykey',
                    keyFileVariable: 'KEY', usernameVariable: 'USER')]) {

                    sh '''
                      ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@target \
                      "sudo mkdir -p /opt/myapp && sudo chown ${USER}:${USER} /opt/myapp"

                      scp -o StrictHostKeyChecking=no -i ${KEY} index.js ${USER}@target:/opt/myapp
                      scp -o StrictHostKeyChecking=no -i ${KEY} -r node_modules ${USER}@target:/opt/myapp
                      scp -o StrictHostKeyChecking=no -i ${KEY} deploy/myapp.service ${USER}@target:/tmp/myapp.service

                      ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@target '
                        if ! node -v | grep v24; then
                          curl -fsSL https://deb.nodesource.com/setup_24.x -o setup.sh
                          sudo -E bash setup.sh
                          sudo apt install -y nodejs
                        fi
                        sudo mv /tmp/myapp.service /etc/systemd/system/myapp.service
                        sudo systemctl daemon-reload
                        sudo systemctl restart myapp
                      '
                    '''
                }
            }
        }

        stage('Deploy to Docker VM') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'mykey',
                    keyFileVariable: 'KEY', usernameVariable: 'USER')]) {

                    sh '''
                      ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@docker "docker stop myapp || true"
                      ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@docker "docker rm myapp || true"
                      ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@docker \
                      "docker run -d --pull always --name myapp -p 4444:4444 ${IMG}"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([string(credentialsId: 'kube-token', variable: 'TOKEN')]) {

                    sh '''
cat > kubeconfig <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: ${KUBE}
    insecure-skip-tls-verify: true
  name: k8s
contexts:
- context:
    cluster: k8s
    user: jenkins
    namespace: ${NS}
  name: ctx
current-context: ctx
users:
- name: jenkins
  user:
    token: ${TOKEN}
EOF

export KUBECONFIG=$PWD/kubeconfig
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deploy/myapp -n ${NS}
                    '''
                }
            }
        }
    }
}
