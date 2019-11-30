# Monitoring Stack

[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/bcochofel/vagrant-monitoring-stack)](https://github.com/bcochofel/vagrant-monitoring-stack/tags)

This project deploys, using vagrant, servers with Prometheus, Telegraf, M3DB, Grafana, and some more components.

This can be used to test configurations for both Prometheus and Grafana.

## Prometheus

Prometheus is configured to scrape metrics from telegraf, node_exporter, grafana and m3db.
The configuration also has the remote read/write option configured for m3db.

## Stress Tests

You can run ```stress-ng``` to test the prometheus alerts.

## Alertmanager

Add environment variable ```SLACK_API_URL``` with your token url for slack notifications.

# Requirements

* Linux, Windows or macOS host with at least 16GB RAM (depends on the project)
* VirtualBox - https://www.virtualbox.org/
* Vagrant - https://www.vagrantup.com/

# Installation

## Deploy servers

To create the servers execute the following commands:

```bash
vagrant plugin install vagrant-hostmanager
vagrant up
```

On Windows take a look at: 

[Vagrant hostmanager plugin](https://github.com/devopsgroup-io/vagrant-hostmanager)

## Deploy monitoring stack

```bash
vagrant ssh mon-1
cd projects/prometheus-configuration
# if you want to send notifications to a slack channel change the file
# alertmanager/alertmanager.yml
docker-compose up -d
```

# High Availability

If you want to deploy everything with High Availability you just need to change some files.
When creating both mon-1 and mon-2 servers the provisioning executes ```git clone``` of the prometheus config repo
under ```/home/vagrant/projects/prometheus-configuration```.
In order to have HA change the following files (relative to repo dir):

- docker-compose.yml
- prometheus/prometheus.yml
- karma/karma.yml
- grafana/config.grafana
- alertmanager/alertmanager.yml

You need to change this files on both mon-1 and mon-2.

## docker-compose.yml

Under ```alertmanager``` section change the line:

```bash
#      - '--cluster.peer=alertmanager2:9094'
```

to (for mon-1)

```bash
      - '--cluster.peer=mon-2:9094'
```

and (for mon-2)

```bash
      - '--cluster.peer=mon-1:9094'
```

Uncomment the line (on both mon-1 and mon-2):

```bash
#      - 9094:9094
```

## prometheus/prometheus.yml

Change the alerting section from:

```bash
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - alertmanager:9093
#      - alertmanager2:9093
```

to (on both mon-1 and mon-2):

```bash
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - mon-1:9093
      - mon-2:9093
```

Uncomment remote read/write block and change the server
At the end the block should look like this:

```bash
# remote read/write to/from M3DB
remote_read:
  - url: 'http://mon-lts:7201/api/v1/prom/remote/read'
    # to test reading even when local Prometheus has the data
    read_recent: true
remote_write:
  - url: 'http://mon-lts:7201/api/v1/prom/remote/write'
```

Change the targets on every job to scrape from both mon-1 and mon-2, except for the m3.
The m3 job should be uncommented and change the m3db-server to mon-lts.

## karma/karma.yml

Change the file from (on both mon-1 and mon-2):

```bash
alertmanager:
  interval: 30s
  servers:
    - name: alertmanager1
      uri: http://alertmanager:9093
      timeout: 20s
      proxy: true
#    - name: alertmanager2
#      uri: http://alertmanager2:9093
#      timeout: 20s
#      proxy: true
```

to:

```bash
alertmanager:
  interval: 30s
  servers:
    - name: alertmanager1
      uri: http://mon-1:9093
      timeout: 20s
      proxy: true
    - name: alertmanager2
      uri: http://mon-2:9093
      timeout: 20s
      proxy: true
```

## grafana/config.grafana

Change the variables PROM_SERVER_ADDR and PROM_SERVER_PORT to mon-lts and 7201 respectively.

## alertmanager/alertmanager.yml

Change the configuration to send notifications to Slack (or something else).

# TODO

- Grafana Provisioning
- Alerta HA configuration

# External Links

- [Prometheus Config Repo](https://github.com/bcochofel/prometheus-configuration)
- [Prometheus](https://prometheus.io/)
- [M3DB](https://www.m3db.io/)
- [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/)
- [Grafana](https://grafana.com/)
- [Stress-ng](https://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/)
- [Weave Net](https://www.weave.works/oss/net/)
