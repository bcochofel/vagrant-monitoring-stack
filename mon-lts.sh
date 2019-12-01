#!/bin/bash

# install packages
sudo yum -q -y install epel-release
sudo yum -q -y install yum-utils
sudo yum -q -y groupinstall development
sudo yum -q -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum -q -y install python3
sudo yum -q -y install python3-pip
sudo yum -q -y install python3-devel
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
  "retentionTime": "12h"
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

exit 0
