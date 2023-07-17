ARGUMENT_LIST=(
  "opt"
  "address"
  "address-benchmark"
  "user"
  "arch"
  "workpath"
  "interface"
  "headnode"
  "num-workers"
  "vm-cpu"
  "vm-mem"
  "vm-image"
  "k3s-version"
  "k3s-port"
  "k3s-token"
  "openfaas-version"
  "openfaas-port"
  "openfaas-namespace"
  "openfaas-functions"
  "nebula-version"
  "nebula-address"
  "nebula-port"
  "repo-name"
  "repo-port"
  "repo-ip"
  "delay-tm"
  "variance-tm"
  "loss-tm"
  "interface-tm"
  "delay-intra"
  "variance-intra"
  "loss-intra"
  "debug"
)

print_param(){
    if [ ! -z "$1" ]; then
    echo -e "==> $2: $1"
    fi
}

opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)

eval set --$opts
while [[ $# -gt 0 ]]; do
case "$1" in
    --opt) OPT=$2;print_param ${OPT} "opt";shift 2;;
    --address) ADDRESS=$2;print_param ${ADDRESS} "address";shift 2;;
    --address-benchmark) ADDRESS_BENCHMARK=$2;print_param ${ADDRESS_BENCHMARK} "address-benchmark";shift 2;;
    --user) USER=$2;print_param ${USER} "user";shift 2;;
    --arch) ARCH=$2;print_param ${ARCH} "arch";shift 2;;
    --workpath) WORKPATH=$2;print_param ${WORKPATH} "workpath";shift 2;;
    --interface) INTERFACE=$2;print_param ${INTERFACE} "interface";shift 2;;
    --headnode) HEADNODE=$2;print_param ${HEADNODE} "headnode";shift 2;;
    --num-workers) NUM_WORKERS=$2;print_param ${NUM_WORKERS} "num-workers";shift 2;;
    --vm-cpu) VM_CPU=$2;print_param ${VM_CPU} "vm-cpu";shift 2;;
    --vm-mem) VM_MEM=$2;print_param ${VM_MEM} "vm-mem";shift 2;;
    --vm-image) VM_IMAGE=$2;print_param ${VM_IMAGE} "vm-image";shift 2;;
    --k3s-version) K3S_VERSION=$2;print_param ${K3S_VERSION} "k3s-version";shift 2;;
    --k3s-port) K3S_PORT=$2;print_param ${K3S_PORT} "k3s-port";shift 2;;
    --k3s-token) K3S_TOKEN=$2;print_param ${K3S_TOKEN} "k3s-token";shift 2;;
    --openfaas-version) OPENFAAS_VERSION=$2;print_param ${OPENFAAS_VERSION} "openfaas-version";shift 2;;
    --openfaas-port) OPENFAAS_PORT=$2;print_param ${OPENFAAS_PORT} "openfaas-port";shift 2;;
    --openfaas-namespace) OPENFAAS_NAMESPACE=$2;print_param ${OPENFAAS_NAMESPACE} "openfaas-namespace";shift 2;;
    --openfaas-functions) OPENFAAS_FUNCTIONS=$2;print_param ${OPENFAAS_FUNCTIONS} "openfaas-functions";shift 2;;
    --nebula-version) NEBULA_VERSION=$2;print_param ${NEBULA_VERSION} "nebula-version";shift 2;;
    --nebula-address) NEBULA_ADDRESS=$2;print_param ${NEBULA_ADDRESS} "nebula-address";shift 2;;
    --nebula-port) NEBULA_PORT=$2;print_param ${NEBULA_PORT} "nebula-port";shift 2;;
    --repo-name) REPO_NAME=$2;print_param ${REPO_NAME} "repo-name";shift 2;;
    --repo-port) REPO_PORT=$2;print_param ${REPO_PORT} "repo-port";shift 2;;
    --repo-ip) REPO_IP=$2;print_param ${REPO_IP} "repo-ip";shift 2;;
    --interface-tm) INTERFACE_TM=$2;print_param ${INTERFACE_TM} "interface-tm";shift 2;;
    --delay-tm) DELAY_TM=$2;print_param ${DELAY_TM} "delay-tm";shift 2;;
    --variance-tm) VARIANCE_TM=$2;print_param ${VARIANCE_TM} "variance-tm";shift 2;;
    --loss-tm) LOSS_TM=$2;print_param ${LOSS_TM} "loss-tm";shift 2;;
    --delay-intra) DELAY_INTRA=$2;print_param ${DELAY_INTRA} "delay-intra";shift 2;;
    --variance-intra) VARIANCE_INTRA=$2;print_param ${VARIANCE_INTRA} "variance-intra";shift 2;;
    --loss-intra) LOSS_INTRA=$2;print_param ${LOSS_INTRA} "loss-intra";shift 2;;
    --debug) DEBUG=$2;print_param ${DEBUG} "debug";shift 2;;
    *)
    break
    ;;
esac
done