install_repo_vagrant() {
	cd /vagrant
	REPONAME=$1
	REPOPORT=$2
	REPOIP=$3  #IP of the registry in case it is local and thus 'insecure'
	echo "Reading config for repo $REPONAME at $REPOIP:$REPOPORT"
	echo "export TERM=xterm" >> ~/.bashrc
	sudo mkdir -p /etc/rancher/k3s
	if [[ -n $REPOIP ]]; then
		if [[ -n $(cat /etc/hosts | grep ${REPONAME}) ]]
		then
			sudo sed -i "/${REPONAME}$/d" /etc/hosts
		fi
		echo "Private container registry defined, applying settings..."
		cat << EOF | sudo tee /etc/rancher/k3s/registries.yaml > /dev/null
mirrors:
  "${REPONAME}:${REPOPORT}":
    endpoint:
      - "http://${REPONAME}:${REPOPORT}"
EOF
	        echo "${REPOIP} ${REPONAME}" | sudo tee -a /etc/hosts > /dev/null
		sudo systemctl restart k3s*
fi
}

install_repo() {
	echo "export TERM=xterm" >> ~/.bashrc
	sudo mkdir -p /etc/rancher/k3s
	if [[ -n $REPOIP ]]; then
		if [[ -n $(cat /etc/hosts | grep ${REPONAME}) ]]
		then
			sudo sed -i "/${REPONAME}$/d" /etc/hosts
		fi
		echo "Private container registry defined, applying settings..."
		cat << EOF | sudo tee /etc/rancher/k3s/registries.yaml > /dev/null
mirrors:
  "${REPONAME}:${REPOPORT}":
    endpoint:
      - "http://${REPONAME}:${REPOPORT}"
EOF
	        echo "${REPOIP} ${REPONAME}" | sudo tee -a /etc/hosts > /dev/null
		sudo systemctl restart k3s*
fi
}

case "$1" in
  (install_repo_vagrant) 
    install_repo_vagrant $2 $3 $4
    exit 1
    ;;
  (install_repo)
    install_repo 
    exit 0
    ;;
  (*)
    echo "Usage: $0 {clean|deploy}"
    exit 2
    ;;
esac

