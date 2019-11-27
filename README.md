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

To create the servers execute the following commands:

```bash
vagrant plugin install vagrant-hostmanager
vagrant up
```

On Windows take a look at: 

[Vagrant hostmanager plugin](https://github.com/devopsgroup-io/vagrant-hostmanager)

# TODO

- Alerta HA configuration

# External Links

- [Prometheus](https://prometheus.io/)
- [M3DB](https://www.m3db.io/)
- [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/)
- [Grafana](https://grafana.com/)
- [Stress-ng](https://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/)
- [Weave Net](https://www.weave.works/oss/net/)
