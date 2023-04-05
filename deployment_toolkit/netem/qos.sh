#!/bin/bash

qos_apply() {
	ssh -n $USER@$ADDRESS "sudo tc qdisc delete dev $INTERFACE root"
	if [[ -z $DELAY_INTRA && -z $DELAY_INTRA && -z $VARIANCE_INTRA && -z $INTERFACE ]]
        then
		echo "Applying $QOS latency (${DELAY_INTRA}ms ${VARIANCE_INTRA}ms ${LOSS_INTRA}%) to $ADDRESS"
		ssh -n $USER@$ADDRESS "sudo tc qdisc add dev $QOSIF root netem delay ${DELAY_INTRA}ms ${VARIANCE_INTRA}ms distribution normal loss ${LOSS_INTRA}%"
	else
		echo "No QoS to apply"
	fi
}

qos_apply_hypervisor_mode() {
	sudo tc qdisc delete dev $INTERFACE_TM root
	if [[ -z $DELAY_TM && -z $VARIANCE_TM && -z $LOSS_TM && -z $INTERFACE_TM ]]; then
		echo "Applying latency..."
		sudo tc qdisc add dev $INTERFACE_TM root netem delay ${DELAY_TM}ms ${VARIANCE_TM}ms distribution normal loss ${LOSS_TM}%
	else
		echo "No QoS to apply"
	fi
}
