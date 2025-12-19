pipeline {
  agent any

  tools {
    nodejs "node24"   // change to your Jenkins NodeJS tool name
  }

  environment {
    APP   = "myapp"
    PORT  = "4444"
    IMG   = "ttl.sh/myapp:2h"
    KUBE  = "https://kubernetes:6443"
    NS    = "production"
    TARGET_DIR = "/opt/myapp"
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
        sh """
          docker build -t ${IMG} .
          docker push ${IMG}
        """
      }
    }

    stage('Deploy to Target VM (systemd)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'mykey', keyFileVariable: 'KEY', usernameVariable: 'USER')]) {
          sh """
            ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@target 'sudo mkdir -p ${TARGET_DIR} && sudo chown -R ${USER}:${USER} ${TARGET_DIR}'
            scp -o StrictHostKeyChecking=no -i ${KEY} index.js ${USER}@target:${TARGET_DIR}/index.js
            scp -o StrictHostKeyChecking=no -i ${KEY} -r node_modules ${USER}@target:${TARGET_DIR}/node_modules
            scp -o StrictHostKeyChecking=no -i ${KEY} deploy/myapp.service ${USER}@target:/tmp/myapp.service

            ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@target '
              if ! node -v 2>/dev/null | grep -q "^v24"; then
                curl -fsSL https://deb.nodesource.com/setup_24.x -o nodesource_setup.sh
                sudo -E bash nodesource_setup.sh
                sudo apt-get update
                sudo apt-get install -y nodejs
              fi
              sudo mv /tmp/myapp.service /etc/systemd/system/myapp.service
              sudo systemctl daemon-reload
              sudo systemctl enable myapp
              sudo systemctl restart myapp
            '
          """
        }
      }
    }

    stage('Deploy to Docker VM') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'mykey', keyFileVariable: 'KEY', usernameVariable: 'USER')]) {
          sh """
            ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@docker 'docker stop ${APP} || true'
            ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@docker 'docker rm ${APP} || true'
            ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@docker 'docker run --name ${APP} --pull always -d -p ${PORT}:${PORT} ${IMG}'
          """
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([string(credentialsId: 'kube-token', variable: 'KUBE_TOKEN')]) {
          sh """
            cat > kubeconfig <<EOF
apiVersion: v1
kind: Config
clusters:
- name: k8s
  cluster:
    server: ${KUBE}
    insecure-skip-tls-verify: true
contexts:
- name: ctx
  context:
    cluster: k8s
    user: jenkins
    namespace: ${NS}
current-context: ctx
users:
- name: jenkins
  user:
    token: ${KUBE_TOKEN}
EOF

            export KUBECONFIG=$PWD/kubeconfig

            kubectl create ns ${NS} --dry-run=client -o yaml | kubectl apply -f -

            # overwrite image to ttl.sh so K8s can pull
            kubectl -n ${NS} apply -f k8s/service.yaml
            kubectl -n ${NS} apply -f k8s/deployment.yaml
            kubectl -n ${NS} set image deploy/${APP} ${APP}=${IMG} --record=true

            kubectl -n ${NS} rollout status deploy/${APP} --timeout=120s
          """
        }
      }
    }
  }
}
