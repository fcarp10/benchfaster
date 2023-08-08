#!/bin/bash

functions_deploy() {
    TOOLKITPATH=$2
	for funct in $1
	do
		echo "Deploying $funct from ${REPOSITORY}$(cat $TOOLKITPATH/openfaas-fn/${funct}.yml | grep image | awk '{print $2}')"
		faas-cli deploy --image=${REPOSITORY}/$(cat $TOOLKITPATH/openfaas-fn/${funct}.yml | grep image | awk '{print $2}') -f $TOOLKITPATH/openfaas-fn/${funct}.yml
			sleep 2
			if [ -f $TOOLKITPATH/openfaas-fn/${funct}-hpa.yml ]
			then
					kubectl apply -f $TOOLKITPATH/openfaas-fn/${funct}-hpa.yml
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
		kubectl -n openfaas-fn rollout status deploy/$funct --timeout=600s
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

TOOLKITPATH="/tmp/benchfaster/payload"
echo $TOOLKITPATH
cd $TOOLKITPATH

if [[ $REPO_NAME != "" && $REPO_PORT != "" ]]
then
    REPOSITORY="${REPO_NAME}:${REPO_PORT}/"
    echo "Using local registry [${REPOSITORY}]..."
else
    REPOSITORY=""
fi

echo "export TERM=xterm" >> ~/.bashrc
echo "Installing faas-cli"
curl -sL https://cli.openfaas.com | sh
while [ $? -ne 0 ]; do curl -sL https://cli.openfaas.com | sh; done
echo "Deploying openfaas..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
#echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/`whoami`/.bashrc
for worker in $(kubectl get nodes | grep -v control-plane | grep -v NAME \
    | sed 's/\s.*$//')
do
    kubectl label node $worker node-role.kubernetes.io/worker=worker
done
curl -sSLf https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    | bash
kubectl apply -f $TOOLKITPATH/openfaas-ns.yml
#Apply the changed defaults to openfaas namespace (and thus to all core components)
kubectl apply -f $TOOLKITPATH/memory-defaults.yaml --namespace=openfaas
#Apply the changed defaults to function namespace (and thus to all deployed containers)
kubectl apply -f $TOOLKITPATH/memory-defaults.yaml --namespace=$OPENFAAS_NAMESPACE

if [ "$DEBUG" = 'true' ]; then
    echo "Adding Grafana..."
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    helm upgrade grafana -n openfaas --install grafana/grafana --version 6.18.0 -f $PWD/debug_tools/grafana.yml
    kubectl -n openfaas apply -f $TOOLKITPATH/grafana-db-map.yml
fi

echo "Adding OpenFaaS..."
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm repo update
sleep 5
TIMEOUT=2m

helm upgrade openfaas --install openfaas/openfaas \
    --namespace openfaas \
    --set functionNamespace=$OPENFAAS_NAMESPACE \
    --set basic_auth=false \
    --set gateway.directFunctions=false \
    --set gateway.upstreamTimeout=$TIMEOUT \
    --set gateway.writeTimeout=$TIMEOUT \
    --set gateway.readTimeout=$TIMEOUT \
    --set gateway.nodePort=$OPENFAAS_PORT \
    --set faasnetes.writeTimeout=$TIMEOUT \
    --set faasnetes.readTimeout=$TIMEOUT \
    --set queueWorker.ackWait=$TIMEOUT \
    --set faasnetes.image=${REPOSITORY}michalkeit/faas-netes:0.13.2 \
    --set gateway.image=${REPOSITORY}ghcr.io/openfaas/gateway:0.27.0 \
    --set queueWorker.image=${REPOSITORY}ghcr.io/openfaas/queue-worker:0.14.0 \
    --set prometheus.image=${REPOSITORY}prom/prometheus:v2.46.0 \
    --set alertmanager.image=${REPOSITORY}prom/alertmanager:v0.25.0 \
    --set nats.image=${REPOSITORY}nats-streaming:0.25.5 \
    --version $OPENFAAS_VERSION
if [ $? -ne 0 ]; then echo "There was an error while deploying OpenFaaS. Aborting..." \
    && exit 1; fi
sleep 120
if [ "$DEBUG" = 'true' ]; then
    kubectl -n openfaas rollout status -w deployment/grafana
    kubectl -n openfaas exec -ti deployment/grafana -c grafana -- grafana-cli admin reset-admin-password password
fi
kubectl -n openfaas rollout status -w deployment/gateway
kubectl autoscale deployment -n openfaas gateway --min=1 --max=1

echo "Testing OpenFaaS..."
kubectl -n openfaas get deployments -l "release=openfaas, app=openfaas"
export OPENFAAS_URL=http://127.0.0.1:$OPENFAAS_PORT
#echo "export OPENFAAS_URL=http://127.0.0.1:$OPENFAAS_PORT" >> /home/`whoami`/.bashrc

# Configuring metrics
if [ "$DEBUG" = 'true' ]; then
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install metrics-prometheus prometheus-community/prometheus-adapter --namespace openfaas --set image.repository=${REPOSITORY}directxman12/k8s-prometheus-adapter -f $PWD/debug_tools/prometheus.yaml
fi

echo "Deploying [$OPENFAAS_FUNCTIONS] functions..."
kubectl scale -n openfaas deploy/alertmanager --replicas=0
sleep 2
functions_deploy $OPENFAAS_FUNCTIONS $TOOLKITPATH
sleep 5
functions_check $OPENFAAS_FUNCTIONS

echo "Summarizing setup:"
kubectl -n default get pods --all-namespaces
kubectl get nodes
