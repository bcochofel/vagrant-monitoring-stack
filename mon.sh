#!/bin/bash

NEXP_VER=${1:-'0.18.1'}

sudo yum -y install epel-release
sudo yum -y install yum-utils
sudo yum -y groupinstall development
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum -y install python36u
sudo yum -y install python36u-pip
sudo yum -y install python36u-devel
sudo yum -y install ca-certificates
sudo yum -y install sshpass
sudo yum -y install bind-utils
sudo yum -y install wget curl stress stress-ng vim git tree jq
sudo pip3.6 install --upgrade pip
pip3.6 install docker-compose --user

# install weave network
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/weave

# install node_exporter
sudo useradd --no-create-home --shell /bin/false prometheus
export NODE_EXPORTER_VERSION=${NEXP_VER}
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo cat << EOT > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOT
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# install telegraf
sudo cat << EOT > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL 7
baseurl = https://repos.influxdata.com/rhel/7/x86_64/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOT
sudo yum -y install telegraf
sudo telegraf --input-filter cpu:disk:diskio:kernel:mem:processes:net:swap:system:docker:kernel_vmstat:netstat --output-filter prometheus_client config > /etc/telegraf/telegraf.conf
sudo systemctl start telegraf
sudo systemctl enable telegraf
usermod -aG docker telegraf

mkdir projects
cd projects
git clone https://github.com/bcochofel/prometheus-configuration.git
cd prometheus-configuration
sudo cat << EOT > ./prometheus/node_exporter-targets.json
[
  {
    "labels": {
      "environment": "tst",
      "host": "mon-1"
    },
    "targets": [
      "mon-1:9100"
    ]
  },
  {
    "labels": {
      "environment": "dev",
      "host": "mon-2"
    },
    "targets": [
      "mon-2:9100"
    ]
  }
]
EOT
sudo cat << EOT > ./prometheus/telegraf-targets.json
[
  {
    "labels": {
      "environment": "tst",
      "host": "mon-1"
    },
    "targets": [
      "mon-1:9273"
    ]
  },
  {
    "labels": {
      "environment": "dev",
      "host": "mon-2"
    },
    "targets": [
      "mon-2:9273"
    ]
  }
]
EOT
sudo chown vagrant.vagrant /home/vagrant/projects -R

exit 0
