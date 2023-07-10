#!/bin/bash

echo "Cleaning up k3s..."
/usr/local/bin/k3s-uninstall.sh > /dev/null
/usr/local/bin/k3s-agent-uninstall.sh > /dev/null
echo "Installing k3s server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${1} K3S_NODE_NAME="headnode" INSTALL_K3S_EXEC="--advertise-address 192.168.50.99 --flannel-iface nebula --kube-apiserver-arg \"enable-admission-plugins=PodNodeSelector\"" sh -
