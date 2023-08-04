#!/bin/bash

NEBULA_VERSION=$1
NEBULA_CONFIG=$2/benchfaster/nebula/config
ARCH=$3
NEBULA_WORKER=$4

sudo sed -i '/lighthouse/d' /etc/hosts

echo $5 lighthouse | sudo tee -a /etc/hosts

TMP="/tmp"

[ 1 = 2 ]
until [ $? -eq 0 ]; do
    wget https://github.com/slackhq/nebula/releases/download/v$NEBULA_VERSION/nebula-linux-$ARCH.tar.gz -P $TMP -q
done

cd $TMP
tar xvfz nebula-linux-$ARCH.tar.gz
rm $TMP/nebula-linux-$ARCH.tar.gz
sudo mv $TMP/nebula /usr/local/bin/
sudo mv $TMP/nebula-cert /usr/local/bin/

# Copying the configuration files and certificates
sudo rm -rf /etc/nebula
sudo mkdir -p /etc/nebula
if [ $NEBULA_WORKER = "lighthouse" ]; then
    echo "Installing nebula lighthouse..."
    sudo cp $NEBULA_CONFIG/lighthouse.yml /etc/nebula/nebula.yml
else
    echo "Installing nebula client..."
    sudo cp $NEBULA_CONFIG/worker.yml /etc/nebula/nebula.yml
fi
sudo cp $NEBULA_CONFIG/cert/$NEBULA_WORKER.crt /etc/nebula/nebula.crt
sudo cp $NEBULA_CONFIG/cert/$NEBULA_WORKER.key /etc/nebula/nebula.key
sudo cp $NEBULA_CONFIG/cert/ca.crt /etc/nebula/

# Creating and starting the service
cat << EOF | sudo tee /etc/systemd/system/nebula.service
[Unit]
Description=nebula
Wants=basic.target
After=basic.target network.target
Before=sshd.service

[Service]
SyslogIdentifier=nebula
StandardOutput=syslog
StandardError=syslog
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nebula -config /etc/nebula/nebula.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl restart nebula

