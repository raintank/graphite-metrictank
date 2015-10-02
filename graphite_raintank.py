import re
import time
import struct
from elasticsearch import Elasticsearch
import requests
from graphite_api.intervals import Interval, IntervalSet
from graphite_api.node import LeafNode, BranchNode
from flask import g
import structlog
logger = structlog.get_logger('graphite_api')

class NullStatsd():
    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        pass

    def timer(self, key, val=None):
        return self

    def timing(self, key, val):
        pass

try:
    from graphite_api.app import app
    statsd = app.statsd
    assert statsd is not None
except:
    statsd = NullStatsd()


class RaintankMetric(object):
    __slots__ = ('id', 'org_id', 'name', 'metric', 'interval', 'tags',
        'target_type', 'unit', 'lastUpdate', 'public', 'leaf')

    def __init__(self, source, leaf):
        self.leaf = leaf
        for slot in RaintankMetric.__slots__:
            if slot in source:
                setattr(self, slot, source[slot])

    def is_leaf(self):
        #logger.debug("is_leaf", leaf=self.leaf, name=self.name)
        return self.leaf

class RaintankLeafNode(LeafNode):
    __fetch_multi__ = 'raintank'


class RaintankReader(object):
    __slots__ = ('config', 'metric')

    def __init__(self, config, metric):
        self.config = config
        self.metric = metric

    def get_intervals(self):
        return IntervalSet([Interval(0, time.time())])

    def fetch(self, startTime, endTime):
        pass

class RaintankFinder(object):
    __fetch_multi__ = "raintank"

    def __init__(self, config):
        cfg = config.get('raintank', {})
        es = cfg.get('es', {})
        rt = cfg.get('tank', {})
        self.config = {
            "tank": {
               "url": rt.get('url', 'http://localhost:6060')
            },
            "es": {
                "url": es.get('url', 'http://localhost:9200')
            }
        }
        logger.info("initialize RaintankFinder", config=self.config)
        self.es = Elasticsearch([self.config['es']['url']])

    def find_nodes(self, query):
        seen_branches = set()
        leaf_regex = self.compile_regex(query, False)
        #query Elasticsearch for paths
        matches = self.search_series(leaf_regex, query)
        for metric in matches:
            if metric.is_leaf():
                yield RaintankLeafNode(metric.name, RaintankReader(self.config, metric))
            else:
                name = metric.name
                while '.' in name:
                    name = name.rsplit('.', 1)[0]
                    if name not in seen_branches:
                        seen_branches.add(name)
                        if leaf_regex.match(name) is not None:
                            yield BranchNode(name)

    def compile_regex(self, query, branch=False):
        # we turn graphite's custom glob-like thing into a regex, like so:
        # * becomes [^\.]*
        # . becomes \.
        if branch:
            regex = '{0}.*'
        else:
            regex = '^{0}$'

        regex = regex.format(
            query.pattern.replace('.', '\.').replace('*', '[^\.]*').replace('{', '(').replace(',', '|').replace('}', ')')
        )
        logger.debug("compile_regex", pattern=query.pattern, regex=regex)
        return re.compile(regex)

    def search_series(self, leaf_regex, query):
        branch_regex = self.compile_regex(query, True)

        search_body = {
          "query": {
            "filtered": {
              "filter": {
                "or": [
                    {
                        "term": {
                            "org_id": g.org
                        }
                    },
                    {
                        "term": {
                           "public": True
                        }
                    }
                ]
              },
              "query": {
                "regexp": {
                "name": branch_regex.pattern
                }
              }
            }
          }
        }

        with statsd.timer("graphite-api.search_series.es_search.query_duration"):
            ret = self.es.search(index="metric", doc_type="metric_index", body=search_body, size=10000 )
            matches = []
            if len(ret["hits"]["hits"]) > 0:
                for hit in ret["hits"]["hits"]:
                    leaf = False
                    source = hit['_source']
                    if leaf_regex.match(source['name']) is not None:
                        leaf = True
                    matches.append(RaintankMetric(source, leaf))
            logger.debug('search_series', matches=len(matches))
        return matches

    def fetch_multi(self, nodes, start_time, end_time):
        step = None
        node_ids = {}
        for node in nodes:
            node_ids[node.reader.metric.id] = node.path
            if step is None or node.reader.metric.interval < step:
                step = node.reader.metric.interval

        with statsd.timer("graphite-api.fetch.raintank_query.query_duration"):
            data = self.fetch_from_tank(nodes, start_time, end_time)
        series = {}
        delta = None
        with statsd.timer("graphite-api.fetch.unmarshal_raintank_resp.duration"):
            for resp in data:
                path = node_ids[resp['Target']]
                datapoints = []
                next_time = start_time;
                
                max_pos = len(resp['Datapoints'])

                if max_pos == 0:
                    for i in range(int((end_time - start_time) / step)):
                        datapoints.append(None)
                    series[path] = datapoints
                    continue

                pos = 0

                if delta is None:
                    delta = (resp['Datapoints'][0][1] % start_time) % step
                    # ts[0] is always greater then start_time.
                    if delta == 0:
                        delta = step

                while next_time <= end_time:
                    # check if there are missing values from the end of the time window
                    if pos >= max_pos:
                        datapoints.append(None)
                        next_time += step
                        continue

                    ts = resp['Datapoints'][pos][1]
                    # read in the metric value.
                    v = resp['Datapoints'][pos][0]

                    # pad missing points with null.
                    while ts > (next_time + step):
                        datapoints.append(None)
                        next_time += step

                    datapoints.append(v)
                    next_time += step
                    pos += 1
                    if (ts + step) > end_time:
                        break

                series[path] = datapoints

        if delta is None:
            delta = 1
        time_info = (start_time + delta, end_time, step)
        return time_info, series

    def fetch_from_tank(self, nodes, start_time, end_time):
        params = {"render": [], "from": start_time, "to": end_time}
        for node in nodes:
            params['render'].append(node.reader.metric.id)
        url = "%sget" % self.config['tank']['url']
        resp = requests.get(url, params=params)
        logger.debug('fetch_from_tank', url=url, status_code=resp.status_code, body=resp.text)
        return resp.json()