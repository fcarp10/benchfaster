#!/bin/bash

vagrant_deploy(){
    echo "Setting up vagrant..."
	cp $TOOLKITPATH/vagrant/environment.rb $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/NEBULA_VERSION =.*/NEBULA_VERSION = \"$NEBULA_VERSION\"/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/K3S_VERSION =.*/K3S_VERSION = \"$K3S_VERSION\"/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s@VM_IMAGE =.*@VM_IMAGE = \"${VM_IMAGE}\"@g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/INTERFACE =.*/INTERFACE = \"$INTERFACE\"/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/ADDRESS_BENCHMARK =.*/ADDRESS_BENCHMARK = \"$ADDRESS_BENCHMARK\"/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/VM_MEM =.*/VM_MEM = \"$VM_MEM\"/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/VM_CPU =.*/VM_CPU = \"$VM_CPU\"/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/NUM_WORKERS =.*/NUM_WORKERS = $NUM_WORKERS/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/DELAY_INTRA =.*/DELAY_INTRA = $DELAY_INTRA/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/VARIANCE_INTRA =.*/VARIANCE_INTRA = $VARIANCE_INTRA/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s/LOSS_INTRA =.*/LOSS_INTRA = $LOSS_INTRA/g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s@REPO_NAME =.*@REPO_NAME = \"${REPO_NAME}\"@g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s@REPO_PORT =.*@REPO_PORT = \"${REPO_PORT}\"@g" $TOOLKITPATH/vagrant/environment.transfer
	sed -i "s@REPO_IP =.*@REPO_IP = \"${REPO_IP}\"@g" $TOOLKITPATH/vagrant/environment.transfer
	scp $TOOLKITPATH/vagrant/environment.transfer $USER@$ADDRESS:${WORKPATH}benchfaster/deployment_toolkit/vagrant/environment.rb > /dev/null
	rm $TOOLKITPATH/vagrant/environment.transfer

	echo "Cleaning up old VMs..."
	ssh -n ${USER}@${ADDRESS} "chmod +x ${WORKPATH}benchfaster/deployment_toolkit/vagrant/vagrant_remote.sh"
	ssh -n ${USER}@${ADDRESS} "bash ${WORKPATH}benchfaster/deployment_toolkit/vagrant/vagrant_remote.sh clean"

	echo "Deploying VMs..."
	ssh -n $USER@$ADDRESS "chmod +x ${WORKPATH}benchfaster/deployment_toolkit/vagrant/vagrant_remote.sh> /dev/null"
	ssh -n $USER@$ADDRESS "bash ${WORKPATH}benchfaster/deployment_toolkit/vagrant/vagrant_remote.sh deploy '$OPENFAAS_PORT $OPENFAAS_VERSION $OPENFAAS_NAMESPACE $OPENFAAS_FUNCTIONS $DEBUG $REPO_NAME $REPO_PORT'"
}