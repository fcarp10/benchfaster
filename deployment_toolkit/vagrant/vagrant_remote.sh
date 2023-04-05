#!/bin/bash

clean() {
	CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	cd $CURRENT_DIR
	killall -9 vagrant
	killall -9 ruby
	vagrant destroy -f
	NUM_RUNNING_VMS=$(expr $(sudo virsh list --all --uuid | wc -l) - 1)
	echo "$NUM_RUNNING_VMS VM(s) found"

	while [[ $NUM_RUNNING_VMS -gt 0 ]]
	do
		echo "$NUM_RUNNING_VMS VM(s) are still running, destroying..."
		VM_UUIDS=$(sudo virsh list --all --uuid)
		for VM_UUID in $VM_UUIDS
		do
			sudo virsh destroy $VM_UUID
			sudo virsh undefine $VM_UUID --remove-all-storage
			sleep 2
		done
		NUM_RUNNING_VMS=$(expr $(sudo virsh list --all --uuid | wc -l) - 1)
		sleep 2
	done
	echo "All machines destroyed, proceeding..."
}

deploy() {

	OPENFAAS_PORT=$1
	OPENFAAS_VERSION=$2
	OPENFAAS_NAMESPACE=$3
	OPENFAAS_FUNCTIONS=$4
	DEBUG=$5
	REPO_NAME=$6
	REPO_PORT=$7

	CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	cd $CURRENT_DIR
	
	echo "Trying to create the headnode ..."
	[ 1 -eq 2 ]
	while [ $? -ne 0 ]; do sleep 10 && vagrant destroy -f headnode && sleep 10 && vagrant up headnode; done
	sleep 10
	vagrant ssh -c "sudo -E kubectl get nodes"
	echo "currently configured default routes:"
	vagrant ssh -c "ip route sh | grep default"
	echo "Trying to create the workers..."
	[ 1 -eq 2 ]
	while [ $? -ne 0 ]; do sleep 10 && vagrant destroy -f /worker[0-9]/ && sleep 10 && vagrant up /worker[0-9]/; done
	sleep 15
	echo -n "Waiting for all nodes to join the cluster"
	ACTIVENODES=1
	until [[ $(($ACTIVENODES-1)) -eq $NUM_WORKERS ]]
	do
		ACTIVENODES=$(vagrant ssh -c "sudo kubectl get nodes | wc -l")
		echo -n "."
		sleep 1
	done
	echo "Found $ACTIVENODES of $(($NUM_WORKERS+1)) expected"
	vagrant ssh -c "sudo kubectl get nodes"
	echo "All nodes joined, installing openfaas..."
	vagrant ssh -c "/vagrant/benchfaster/deployment_toolkit/openfaas/openfaas_install.sh vm $OPENFAAS_PORT $OPENFAAS_VERSION $OPENFAAS_NAMESPACE $OPENFAAS_FUNCTIONS $DEBUG $REPO_NAME $REPO_PORT"
	if [ $? -ne 0 ]; then echo "There was an error while installing a node. Aborting..." \
		&& exit 1; fi
}

case "$1" in
  (clean) 
    clean
    exit 1
    ;;
  (deploy)
    deploy $2 $3 $4 $5 $6 $7 $8
    exit 0
    ;;
  (*)
    echo "Usage: $0 {clean|deploy}"
    exit 2
    ;;
esac

