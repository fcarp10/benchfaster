#!/bin/bash

qos_apply_hypervisor_mode() {
	sudo tc qdisc delete dev $INTERFACE_TM root
	if [[ -z $DELAY_TM && -z $VARIANCE_TM && -z $LOSS_TM && -z $INTERFACE_TM ]]; then
		echo "Applying QoS ..."
		sudo tc qdisc add dev $INTERFACE_TM root netem delay ${DELAY_TM}ms ${VARIANCE_TM}ms distribution normal loss ${LOSS_TM}%
	else
		echo "No QoS to apply to tester machine"
	fi
}
