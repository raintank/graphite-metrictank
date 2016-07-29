# graphite-raintank

[![Circle CI](https://circleci.com/gh/raintank/graphite-metrictank.svg?style=shield)](https://circleci.com/gh/raintank/graphite-metrictank)

Plugin for graphite-api to use Raintank's Memory+Cassandra backend.
https://github.com/raintank/raintank-metric/tree/tank/nsq_metrics_tank

### Install the plugin:

`pip install git+https://github.com/raintank/graphite-raintank.git`

### set the configuration in /etc/graphite-api.yaml

```
cache:
  CACHE_DIR: /tmp/graphite-api-cache
  CACHE_TYPE: filesystem
finders:
- graphite_raintank.RaintankFinder
functions:
- graphite_api.functions.SeriesFunctions
- graphite_api.functions.PieFunctions
raintank:
  es:
    url: http://elasticsearch:9200/
  tank:
    url: http://nsq_metrics_tank:6060/
search_index: /var/lib/graphite/index
time_zone: America/New_York
```
