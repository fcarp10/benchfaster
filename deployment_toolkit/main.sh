TOOLKITPATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "###########################################"
echo "Parameters"

source $TOOLKITPATH/options.sh

if [ $OPT == "copy" ]; then 
	echo "Copying BenchFaster..."
	ssh -n $USER@$ADDRESS "rm -Rf ${WORKPATH}benchfaster/"
	ssh -n $USER@$ADDRESS "mkdir -p ${WORKPATH}benchfaster/"
	scp -r $TOOLKITPATH $USER@$ADDRESS:${WORKPATH}benchfaster/ > /dev/null
elif [ $OPT == "vagrant" ]; then 
    echo "Starting deployment in hypervisor..."
    source $TOOLKITPATH/vagrant/vagrant_main.sh
    vagrant_deploy
    source $TOOLKITPATH/netem/qos.sh
    qos_apply_hypervisor_mode
	echo "Deployment in hypervisor finished!"
elif  [ $OPT == "k3s" ]; then 
	echo "Starting deployment..."
    source $TOOLKITPATH/k3s/k3s_main.sh
    k3s_install
    source $TOOLKITPATH/netem/qos.sh
	qos_apply
	echo "Deployment finished!"
fi


