apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 4444
          readinessProbe:
            httpGet:
              path: /
              port: 4444
            initialDelaySeconds: 3
            periodSeconds: 5