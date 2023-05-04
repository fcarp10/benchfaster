#!/bin/bash

k3s_install(){
	echo "Cleaning up k3s from $ADDRESS..."
	ssh -n $USER@$ADDRESS "/usr/local/bin/k3s-uninstall.sh > /dev/null"
	ssh -n $USER@$ADDRESS "/usr/local/bin/k3s-agent-uninstall.sh > /dev/null"
    if [ $HEADNODE ]; then
		echo "Installing k3s server..."
		ssh -n $USER@$ADDRESS "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_EXEC=\"--advertise-address 192.168.50.99 --flannel-iface nebula --kube-apiserver-arg \"enable-admission-plugins=PodNodeSelector\"\" sh -"
	else
		echo "Installing k3s agent [K3S_TOKEN: $K3S_TOKEN]..."
		ssh -n $USER@$ADDRESS "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} K3S_URL=https://192.168.50.99:${K3S_PORT} K3S_TOKEN=${K3S_TOKEN} INSTALL_K3S_EXEC=\"--flannel-iface nebula\" sh -"
	fi
}
