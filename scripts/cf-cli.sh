#!/bin/bash

api_ip=$(kubectl get svc -n scf scf-router-0 -o json | jq -r .spec.clusterIP)
admin_password=$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 --decode)

kubectl delete deployment -n scf cf-terminal || true 

kubectl create -n scf -f - <<STDIN
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cf-terminal
  labels:
    app: cf-terminal
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cf-terminal
  template:
    metadata:
      labels:
        app: cf-terminal
    spec:
      hostAliases:
      - ip: "${api_ip}"
        hostnames:
        - "app1.fissile.dev"
        - "app2.fissile.dev"
        - "app3.fissile.dev"
        - "login.fissile.dev"
        - "api.fissile.dev"
        - "uaa.fissile.dev"
        - "doppler.fissile.dev"
        - "log-stream.fissile.dev"
      containers:
      - name: cf-terminal
        image: governmentpaas/cf-cli
        command: ["bash", "-c"]
        args:
        - cf api --skip-ssl-validation api.fissile.dev;
          cf login -u admin -p ${admin_password};
          cf create-org aiur;
          cf target -o aiur;
          cf create-space saalok;
          cf target -s saalok;
          git clone https://github.com/rohitsakala/cf-hello-worlds.git;
          sleep 3600000;
STDIN
