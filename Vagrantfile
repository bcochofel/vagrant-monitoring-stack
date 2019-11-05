# -*- mode: ruby -*-
# vi: set ft=ruby :

### configuration parameters ###

# Vagrant variables
VAGRANTFILE_API_VERSION = "2"

# Telegraf version
TELEGRAF_VERSION = "1.12.4"

# Script to get M3DB + Grafana
$script1 = <<-SCRIPT
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
sudo yum install grafana -y
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server.service
SCRIPT

# Script to configure servers
$script2 = <<-SCRIPT
sudo yum -y install epel-release
sudo yum -y install python-pip
sudo yum -y install python-devel
sudo yum -y install wget curl
sudo pip install --upgrade pip
sudo pip install jsondiff
sudo pip install pyyamlA

# install/configure prometheus
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
export PROMETHEUS_VERSION=2.13.1
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
mv prometheus-${PROMETHEUS_VERSION}.linux-amd64 prometheuspackage
sudo cp prometheuspackage/prometheus /usr/local/bin/
sudo cp prometheuspackage/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo cp -r prometheuspackage/consoles /etc/prometheus
sudo cp -r prometheuspackage/console_libraries /etc/prometheus
sudo cat << EOT > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 10s

# Alertmanager configuration
# alerting:
#   alertmanagers:
#   - static_configs:
#       - targets: ['localhost:9093']

# Load rules once and periodically evaluate them according 
# to the global 'evaluation_interval'.
rule_files:
  - "rules/*.rules.yml"

remote_read:
  - url: "http://mon-lts:7201/api/v1/prom/remote/read"
    # To test reading even when local Prometheus has the data
    read_recent: true
remote_write:
  - url: "http://mon-lts:7201/api/v1/prom/remote/write"

scrape_configs:
  - job_name: 'prometheus_master'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['mon-1:9100']

  - job_name: 'telegraf'
    static_configs:
      - targets: ['mon-1:9273']

  - job_name: 'm3'
    static_configs:
      - targets: ['mon-lts:7203']
EOT
sudo chown -R prometheus:prometheus /etc/prometheus
sudo cat << EOT > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOT
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# install node_exporter
export NODE_EXPORTER_VERSION=0.18.1
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
SCRIPT

# Manager Servers
managers = [
  { :hostname => 'mon-lts', :ip => '192.168.77.2', :ram => 8192, :cpus => 4, :box => "bento/centos-7.7" }
]

# Monitoring Servers
servers = [
  { :hostname => 'mon-1', :ip => '192.168.77.10', :ram => 2048, :cpus => 2, :box => "bento/centos-7.7" }
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # vagrant-hostmanager options
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = false

  # Always use Vagrant's insecure key
  #config.ssh.insert_key = false
  
  # Forward ssh agent to easily ssh into the different machines
  config.ssh.forward_agent = true

  # Synced Folder
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # Manager Server
  managers.each do |manager|
    config.vm.define manager[:hostname] do |config|
      config.vm.hostname = manager[:hostname]

      # Vagrant box
      config.vm.box = manager[:box];

      # Docker
      config.vm.provision "docker"

      config.vm.network :private_network, ip: manager[:ip]

      memory = manager[:ram];
      cpus = manager[:cpus];

      config.vm.provider :virtualbox do |vb|
        vb.customize [
          "modifyvm", :id,
          "--memory", memory.to_s,
          "--cpus", cpus.to_s,
          "--ioapic", "on",
          "--natdnshostresolver1", "on",
          "--natdnsproxy1", "on"
        ]
      end

      # Get M3DB docker image
      config.vm.provision "shell", inline: $script1
    end
  end

  # Provision servers
  servers.each do |server|
    config.vm.define server[:hostname] do |config|
      config.vm.hostname = server[:hostname]

      # Vagrant box
      config.vm.box = server[:box];

      # Docker
      config.vm.provision "docker"

      config.vm.network :private_network, ip: server[:ip]

      memory = server[:ram];
      cpus = server[:cpus];

      config.vm.provider :virtualbox do |vb|
        vb.customize [
          "modifyvm", :id,
          "--memory", memory.to_s,
          "--cpus", cpus.to_s,
          "--ioapic", "on",
          "--natdnshostresolver1", "on",
          "--natdnsproxy1", "on"
        ]
      end

      # Configure monitoring stack
      config.vm.provision "shell", inline: $script2
    end
  end
end