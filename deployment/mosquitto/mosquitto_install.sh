#!/bin/bash

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $CURRENT_DIR

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/`whoami`/.bashrc
for worker in $(sudo -E kubectl get nodes | grep -v control-plane | grep -v NAME | sed 's/\s.*$//'); do
    sudo -E kubectl label node $worker node-role.kubernetes.io/worker=worker
done
sudo -E kubectl apply -f namespaces.yml
sudo -E kubectl apply -f memory-defaults.yaml --namespace=mosquitto
sudo -E kubectl apply -f mosquitto.yaml
sudo -E kubectl apply -f mosquitto-svc.yaml
sudo -E kubectl -n mosquitto rollout status -w deployment/mosquitto