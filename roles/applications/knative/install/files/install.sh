#!/bin/bash

DEVTYPE=$1
VERSION=$2
ADDRESS=$3
REPO_NAME=$4
REPO_PORT=$5

if [ $DEVTYPE = "vm" ]
then
    TOOLKITPATH="/vagrant/benchfaster"
    cd $TOOLKITPATH
else
    TOOLKITPATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../
	cd $TOOLKITPATH
fi

if [[ $REPO_NAME != "" && $REPO_PORT != "" ]]
then
    REPOSITORY="${REPO_NAME}:${REPO_PORT}/"
    echo "Using local registry [${REPOSITORY}]..."
else
    REPOSITORY=""
fi

echo "Labelling K3s worker nodes..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
for worker in $(sudo -E kubectl get nodes | grep -v control-plane | grep -v NAME \
    | sed 's/\s.*$//')
do
    sudo -E kubectl label node $worker node-role.kubernetes.io/worker=worker
done

echo "Deploying Knative Serving..."
sudo -E kubectl apply -f https://github.com/knative/serving/releases/download/knative-$VERSION/serving-crds.yaml
sudo -E kubectl apply -f https://github.com/knative/serving/releases/download/knative-$VERSION/serving-core.yaml
sleep 10

echo "Deploying Kourier..."
sudo -E kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-$VERSION/kourier.yaml
sudo -E kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
sudo kubectl patch configmap/config-domain \
  -n knative-serving \
  --type merge \
  -p '{"data":{"'${ADDRESS}'.nip.io":""}}'
sudo -E kubectl patch svc kourier -p '{"spec":{"externalIPs":["'${ADDRESS}'"]}}' -n kourier-system
until sudo kubectl get pods -n kourier-system | grep "1/1" | grep "Running" >/dev/null; do
    echo "Waiting for Kourier to be ready..."
    sleep 10
done
sudo -E kubectl --namespace kourier-system get service kourier

echo "Configuring DNS..."
sudo -E kubectl apply -f https://github.com/knative/serving/releases/download/knative-$VERSION/serving-default-domain.yaml

echo "Enabling NodeAffinity feature..."
sudo -E kubectl -n knative-serving patch cm config-features -p '{"data": {"kubernetes.podspec-affinity": "enabled"}}'
echo "Knative deployment finished!"
