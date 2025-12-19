pipeline {
  agent any

  environment {
    APP_NAME = "myapp"
    APP_PORT = "4444"
    TARGET_DIR = "/opt/myapp"
    TARGET_SERVICE = "myapp"

    // change these:
    TARGET_HOST = "TARGET_VM_IP_OR_DNS"
    DOCKER_HOST = "DOCKER_VM_IP_OR_DNS"  
    DOCKER_IMAGE = "myapp:latest"

    KUBE_URL = "https://kubernetes:6443"
    KUBE_NS  = "production"
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Use Node 24 + Install deps') {
      steps {
        sh '''
          node -v || true
          npm -v || true
          npm install
        '''
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          node --test
        '''
      }
    }

    stage('Deploy to Target (systemd)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'target-ssh',
                                           keyFileVariable: 'KEY',
                                           usernameVariable: 'USER')]) {
          sh '''
            set -eux

            # Copy app (index.js + node_modules + service file)
            ssh -o StrictHostKeyChecking=no -i "$KEY" $USER@$TARGET_HOST "sudo mkdir -p ${TARGET_DIR} && sudo chown -R $USER:${USER} ${TARGET_DIR}"

            scp -o StrictHostKeyChecking=no -i "$KEY" index.js $USER@$TARGET_HOST:${TARGET_DIR}/index.js
            scp -o StrictHostKeyChecking=no -i "$KEY" -r node_modules $USER@$TARGET_HOST:${TARGET_DIR}/node_modules
            scp -o StrictHostKeyChecking=no -i "$KEY" deploy/myapp.service $USER@$TARGET_HOST:/tmp/myapp.service

            # Ensure Node 24 exists on target (install if missing)
            ssh -o StrictHostKeyChecking=no -i "$KEY" $USER@$TARGET_HOST '
              if ! node -v | grep -q "^v24"; then
                curl -fsSL https://deb.nodesource.com/setup_24.x -o nodesource_setup.sh
                sudo -E bash nodesource_setup.sh
                sudo apt-get update
                sudo apt-get install -y nodejs
              fi
            '

            # Install/Restart systemd service
            ssh -o StrictHostKeyChecking=no -i "$KEY" $USER@$TARGET_HOST "
              sudo mv /tmp/myapp.service /etc/systemd/system/${TARGET_SERVICE}.service
              sudo systemctl daemon-reload
              sudo systemctl enable ${TARGET_SERVICE}
              sudo systemctl restart ${TARGET_SERVICE}
              sudo systemctl --no-pager --full status ${TARGET_SERVICE} || true
            "
          '''
        }
      }
    }

    stage('Deploy to Docker') {
      steps {
        sh '''
          set -eux
          docker version
          docker build -t ${DOCKER_IMAGE} .
          docker rm -f ${APP_NAME} || true
          docker run -d --name ${APP_NAME} -p ${APP_PORT}:${APP_PORT} ${DOCKER_IMAGE}
          docker ps | grep ${APP_NAME}
        '''
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([string(credentialsId: 'kube-token', variable: 'KUBE_TOKEN')]) {
          sh '''
            set -eux

            # Create minimal kubeconfig for kubectl
            cat > kubeconfig <<EOF
            apiVersion: v1
            kind: Config
            clusters:
            - cluster:
                server: ${KUBE_URL}
                insecure-skip-tls-verify: true
              name: k8s
            contexts:
            - context:
                cluster: k8s
                user: jenkins
                namespace: ${KUBE_NS}
              name: ctx
            current-context: ctx
            users:
            - name: jenkins
              user:
                token: ${KUBE_TOKEN}
            EOF

            export KUBECONFIG=$PWD/kubeconfig

            kubectl apply -f k8s/namespace.yaml
            kubectl -n ${KUBE_NS} apply -f k8s/deployment.yaml
            kubectl -n ${KUBE_NS} apply -f k8s/service.yaml

            kubectl -n ${KUBE_NS} rollout status deploy/${APP_NAME} --timeout=120s
            kubectl -n ${KUBE_NS} get pods -o wide
            kubectl -n ${KUBE_NS} get svc
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'echo "Pipeline finished."'
    }
  }
}