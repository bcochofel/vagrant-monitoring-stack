#!/bin/bash

# install packages
sudo yum -q -y install epel-release
sudo yum -q -y install yum-utils
sudo yum -q -y groupinstall development
sudo yum -q -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum -q -y install python36u
sudo yum -q -y install python36u-pip
sudo yum -q -y install python36u-devel
sudo yum -q -y install ca-certificates
sudo yum -q -y install sshpass
sudo yum -q -y install bind-utils
sudo yum -q -y install wget curl stress stress-ng vim git tree jq

# install weave network
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/weave

# m3db docker
docker pull quay.io/m3db/m3dbnode:latest
docker run -d -p 7201:7201 -p 7203:7203 -p 9003:9003 \
  --name m3db -v $(pwd)/m3db_data:/var/lib/m3db quay.io/m3db/m3dbnode:latest
sleep 30
curl -X POST http://localhost:7201/api/v1/database/create -d '{
  "type": "local",
  "namespaceName": "default",
  "retentionTime": "48h"
}' &>/dev/null

# m3db docker service
sudo cat << EOT > /etc/systemd/system/docker-m3db.service
[Unit]
Description=M3DB container
Requires=docker.service
After=docker.service

[Service]
User=vagrant
Restart=always
RestartSec=10
# ExecStartPre=-/usr/bin/docker kill m3db
# ExecStartPre=-/usr/bin/docker rm m3db
ExecStart=/usr/bin/docker start -a m3db
ExecStop=/usr/bin/docker stop -t 2 m3db

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable docker-m3db

# grafana repository
sudo cat << EOT > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOT

# install grafana
sudo yum -q -y install grafana
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server.service

exit 0
