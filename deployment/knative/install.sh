#!/bin/bash

functions_deploy() {
	for funct in $1; do
		echo "Deploying ${funct}..."
        sudo -E kubectl apply -f $PWD/knative/functions/${funct}.yaml
	done
}

functions_check() {
	for funct in $1; do
		echo "Waiting for function ${funct}..."
		sudo -E kubectl -n default rollout status deploy/${funct}-0-deployment --timeout=60s
		if [ $? -ne 0 ]; then echo "Error: Function ${funct} timed out, continuing..."; fi
	done
}


DEVTYPE=$1
PORT=$2
VERSION=$3
FUNCTIONS=$4
ADDRESS=$5
REPO_NAME=$6
REPO_PORT=$7

if [ $DEVTYPE = "vm" ]
then
    TOOLKITPATH="/vagrant/benchfaster/deployment"
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
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/`whoami`/.bashrc
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
sleep 60 ## TO-DO: implement a function to wait until EXTERNAL-IP is ready 
sudo kubectl patch configmap/config-domain \
  -n knative-serving \
  --type merge \
  -p '{"data":{"'${ADDRESS}'.nip.io":""}}'
sudo -E kubectl patch svc kourier -p '{"spec":{"externalIPs":["'${ADDRESS}'"]}}' -n kourier-system
sudo -E kubectl --namespace kourier-system get service kourier

echo "Configuring DNS..."
sudo -E kubectl apply -f https://github.com/knative/serving/releases/download/knative-$VERSION/serving-default-domain.yaml

# echo "Inslling HPA autoscaling..."
# sudo -E kubectl apply -f https://github.com/knative/serving/releases/download/knative-$VERSION/serving-hpa.yaml

functions_deploy $FUNCTIONS
sleep 5
functions_check $FUNCTIONS
sudo -E kubectl get ksvc -n default
sleep 5

echo "Knative deployment finished!"
