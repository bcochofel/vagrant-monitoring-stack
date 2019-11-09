# Monitoring Stack

[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/bcochofel/vagrant-monitoring-stack)](https://github.com/bcochofel/vagrant-monitoring-stack/tags)

This project deploys, using vagrant, servers with Prometheus, Telegraf, M3DB, Grafana, and some more components.

This can be used to test configurations for both Prometheus and Grafana.

## Prometheus

Prometheus is configured to scrape metrics from telegraf, node_exporter, grafana and m3db.
The configuration also has the remote read/write option configured for m3db.

# External Links

- [Prometheus](https://prometheus.io/)
- [M3DB](https://www.m3db.io/)
- [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/)
- [Grafana](https://grafana.com/)
