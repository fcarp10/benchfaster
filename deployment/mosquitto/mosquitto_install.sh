#!/bin/bash

PAYLOAD_DIR=/tmp/benchfaster/payload

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
for worker in $(sudo -E kubectl get nodes | grep -v control-plane | grep -v NAME | sed 's/\s.*$//'); do
    sudo -E kubectl label node $worker node-role.kubernetes.io/worker=worker
done
sudo -E kubectl apply -f ${PAYLOAD_DIR}/mosquitto-ns.yaml
sudo -E kubectl apply -f ${PAYLOAD_DIR}/memory-defaults.yaml --namespace=mosquitto
sudo -E kubectl apply -f ${PAYLOAD_DIR}/mosquitto.yaml
sudo -E kubectl apply -f ${PAYLOAD_DIR}/mosquitto-svc.yaml
sudo -E kubectl -n mosquitto rollout status -w deployment/mosquitto
