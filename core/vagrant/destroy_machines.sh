cd $1
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
