#!/bin/bash

functions_deploy() {
    TOOLKITPATH=$2
	for funct in $1
	do
		echo "Deploying $funct from ${REPOSITORY}$(cat $TOOLKITPATH/openfaas/functions/${funct}.yml | grep image | awk '{print $2}')"
		sudo -E faas-cli deploy --image=${REPOSITORY}/$(cat $TOOLKITPATH/openfaas/functions/${funct}.yml | grep image | awk '{print $2}') -f $TOOLKITPATH/openfaas/functions/${funct}.yml
			sleep 2
			if [ -f $TOOLKITPATH/openfaas/functions/${funct}-hpa.yml ]
			then
					sudo -E kubectl apply -f $TOOLKITPATH/openfaas/functions/${funct}-hpa.yml
			if [ $? -ne 0 ]; then echo "There was an error while deploying $funct. Aborting..." \
			&& exit 2; fi
					sleep 2
			fi
	done
}

functions_check() {
	for funct in $1
	do
		echo "Waiting for function $funct to deploy successfully..."
		sudo -E kubectl -n openfaas-fn rollout status deploy/$funct --timeout=600s
		if [ $? -ne 0 ]; then echo "The function $funct timed out, continuing anyway but this might cause problems with the tests..."; fi
	done
}


DEVTYPE=$1
OPENFAAS_PORT=$2
OPENFAAS_VERSION=$3
OPENFAAS_NAMESPACE=$4
OPENFAAS_FUNCTIONS=$5
DEBUG=$6
REPO_NAME=$7
REPO_PORT=$8

if [ $DEVTYPE = "vm" ]
then
    TOOLKITPATH="/vagrant/benchfaster/deployment_toolkit"
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

echo "export TERM=xterm" >> ~/.bashrc
echo "Installing faas-cli"
curl -sL https://cli.openfaas.com | sudo -E sh
while [ $? -ne 0 ]; do curl -sL https://cli.openfaas.com | sudo -E sh; done
echo "Deploying openfaas..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/`whoami`/.bashrc
WORKERNUMBER=0
for worker in $(sudo -E kubectl get nodes | grep -v control-plane | grep -v NAME \
    | sed 's/\s.*$//')
do
    sudo -E kubectl label node $worker node-role.kubernetes.io/worker=worker
    WORKERNUMBER=$((WORKERNUMBER+1))
done
curl -sSLf https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    | bash
sudo -E kubectl apply -f $PWD/openfaas/namespaces.yml
#Apply the changed defaults to openfaas namespace (and thus to all core components)
sudo -E kubectl apply -f $PWD/openfaas/memory-defaults.yaml --namespace=openfaas
#Apply the changed defaults to function namespace (and thus to all deployed containers)
sudo -E kubectl apply -f $PWD/openfaas/memory-defaults.yaml --namespace=$OPENFAAS_NAMESPACE

if [ "$DEBUG" = 'true' ]; then
    echo "Adding Grafana..."
    sudo -E helm repo add grafana https://grafana.github.io/helm-charts
    sudo -E helm repo update
    sudo -E helm upgrade grafana -n openfaas --install grafana/grafana --version 6.18.0 -f $PWD/debug_tools/grafana.yml
    sudo -E kubectl -n openfaas apply -f $PWD/debug_tools/grafana-db-map.yml
fi

echo "Adding OpenFaaS..."
sudo -E helm repo add openfaas https://openfaas.github.io/faas-netes/
sudo -E helm repo update
sleep 2
sudo -E kubectl -n openfaas create secret generic basic-auth \
    --from-literal=basic-auth-user=admin \
    --from-literal=basic-auth-password=password
sleep 5
TIMEOUT=2m

sudo -E helm upgrade openfaas --install openfaas/openfaas --namespace openfaas \
    --set functionNamespace=$OPENFAAS_NAMESPACE --set basic_auth=true \
    --set gateway.directFunctions=false \
    --set gateway.upstreamTimeout=$TIMEOUT \
    --set gateway.writeTimeout=$TIMEOUT \
    --set gateway.readTimeout=$TIMEOUT \
    --set gateway.nodePort=$OPENFAAS_PORT \
    --set faasnetes.writeTimeout=$TIMEOUT \
    --set faasnetes.readTimeout=$TIMEOUT \
    --set queueWorker.ackWait=$TIMEOUT \
    --set faasnetes.image=${REPOSITORY}ghcr.io/openfaas/faas-netes:0.13.2 \
    --set nats.image=${REPOSITORY}nats-streaming:0.22.0 \
    --set queueWorker.image=${REPOSITORY}ghcr.io/openfaas/queue-worker:0.12.2 \
    --set prometheus.image=${REPOSITORY}prom/prometheus:v2.11.0 \
    --set basicAuthPlugin.image=${REPOSITORY}ghcr.io/openfaas/basic-auth:0.21.1 \
    --version $OPENFAAS_VERSION
if [ $? -ne 0 ]; then echo "There was an error while deploying OpenFaaS. Aborting..." \
    && exit 1; fi
sleep 120
if [ "$DEBUG" = 'true' ]; then
    sudo -E kubectl -n openfaas rollout status -w deployment/grafana
    sudo -E kubectl -n openfaas exec -ti deployment/grafana -c grafana -- grafana-cli admin reset-admin-password password
fi
sudo -E kubectl -n openfaas rollout status -w deployment/gateway
sudo -E kubectl autoscale deployment -n openfaas gateway --min=1 --max=1

echo "Testing OpenFaaS..."
sudo -E kubectl -n openfaas get deployments -l "release=openfaas, app=openfaas"
export OPENFAAS_URL=http://127.0.0.1:$OPENFAAS_PORT
echo "export OPENFAAS_URL=http://127.0.0.1:$OPENFAAS_PORT" >> /home/`whoami`/.bashrc
sudo -E faas-cli login --username admin --password password

# Configuring metrics
sudo -E helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo -E helm repo update
sudo -E helm install metrics-prometheus prometheus-community/prometheus-adapter --namespace openfaas --set image.repository=${REPOSITORY}directxman12/k8s-prometheus-adapter -f $PWD/debug_tools/prometheus.yaml

echo "Deploying [$OPENFAAS_FUNCTIONS] functions..."
sudo -E kubectl scale -n openfaas deploy/alertmanager --replicas=0
sleep 2
functions_deploy $OPENFAAS_FUNCTIONS $TOOLKITPATH
sleep 5
functions_check $OPENFAAS_FUNCTIONS

echo "Summarizing setup:"
sudo -E kubectl -n default get pods --all-namespaces
sudo -E k3s kubectl get nodes


