# -*- mode: ruby -*-
# vi: set ft=ruby :

### configuration parameters ###

# Vagrant variables
VAGRANTFILE_API_VERSION = "2"

# Prometheus version
PROMETHEUS_VERSION = "2.13.1"

# Alertmanager version
ALERTMANAGER_VERSION = "0.19.0"

# Node exporter version
NODE_EXPORTER_VERSION = "0.18.1"

# SLACK API URL
SLACK_API_URL = ENV["SLACK_API_URL"] || 'https://hooks.slack.com/services'

# Manager Servers
managers = [
  { :hostname => 'mon-lts', :ip => '192.168.77.2', :ram => 6144, :cpus => 4, :box => "bento/centos-7.7" }
]

# Monitoring Servers
servers = [
  { :hostname => 'mon-1', :ip => '192.168.77.10', :ram => 1024, :cpus => 2, :box => "bento/centos-7.7" },
  { :hostname => 'mon-2', :ip => '192.168.77.20', :ram => 1024, :cpus => 2, :box => "bento/centos-7.7" }
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
      config.vm.provision "shell", path: "mon-lts.sh"
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
      config.vm.provision "shell" do |s|
        s.path = "mon.sh"
        s.args = [NODE_EXPORTER_VERSION]
      end

      # Configure with ansible
      config.vm.provision "playbook", type: "ansible" do |ansible|
        ansible.compatibility_mode = "auto"
        ansible.config_file = "ansible/ansible.cfg"
        ansible.playbook = "ansible/playbook.yml"
        ansible.limit = "mon-1,mon-2"
      end
    end
  end
end
