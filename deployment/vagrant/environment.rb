# Variables that are host-specific or will be changed for tests
module Variables
    $VAGRANT_PROVIDER = "libvirt"
    $INTERFACE = ""
    $ADDRESS_BENCHMARK = ""
    $VM_IMAGE = ""
    $NEBULA_VERSION = ""
    $K3S_VERSION = ""
    $DELAY_INTRA = 0
    $VARIANCE_INTRA = 0
    $LOSS_INTRA = 0
    $NUM_WORKERS = 0
    $VM_MEM = ""
    $VM_CPU = ""
    $REPO_NAME = ""
    $REPO_PORT = ""
    $REPO_IP = ""
end
