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
import json

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


def is_pattern(s):
    return '*' in s or '?' in s or '[' in s or '{' in s

class RaintankMetric(object):
    __slots__ = ('id', 'org_id', 'name', 'metric', 'interval', 'tags',
        'target_type', 'unit', 'lastUpdate', 'public', 'node_count', 'nodes', 'leaf')

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
    __slots__ = ('config', 'metrics')

    def __init__(self, config, metrics):
        self.config = config
        self.metrics = metrics

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
                "url": es.get('url', 'http://localhost:9200'),
                "index": es.get('index', "metric")
            }
        }
        logger.info("initialize RaintankFinder", config=self.config)
        self.es = Elasticsearch([self.config['es']['url']])

    def find_nodes(self, query):
        seen_branches = set()
        #query Elasticsearch for paths
        matches = self.search_series(query)

        for name, metrics in matches['leafs'].iteritems():    
            yield RaintankLeafNode(name, RaintankReader(self.config, metrics))
        for branchName in matches['branches']:
            yield BranchNode(branchName)

    def search_series(self, query):
        parts = query.pattern.split(".")
        part_len = len(parts)
        es_query = {
            "bool": {
                "must": [
                ]
            }
        }
        pos = 0
        for p in parts:
            node = "nodes.n%d" % pos
            value = p
            q_type = "term"
            if is_pattern(p):
                q_type = "regexp"
                value = p.replace('*', '.*').replace('{', '(').replace(',', '|').replace('}', ')')

            es_query['bool']['must'].append({q_type: {node: value}})
            pos += 1

        leaf_search_body = {
          "size": 500,
          "query": {
                "filtered": {
                    "filter": {
                        "bool": {
                            "must": [
                                { 
                                    "term" : {
                                        "node_count": part_len
                                    }
                                }
                            ],
                            "should": [
                                {
                                    "term": {
                                        "org_id": g.org
                                    }
                                },
                                {
                                    "term": {
                                       "org_id": -1
                                    }
                                }
                            ]
                        }
                    },
                "query": es_query
                }
            }
        }
        leaf_query = json.dumps(leaf_search_body)
        search_body = '{"index": "'+self.config['es']['index']+'", "type": "metric_index"}' + "\n" + leaf_query +"\n"

        if not query.leaves_only:
            branch_search_body = leaf_search_body
            branch_search_body["query"]["filtered"]["filter"]["bool"]["must"][0] = {"range": {"node_count": {"gt": part_len}}}
            branch_search_body["aggs"] = {
                "branches" : {
                    "terms": {
                        "field": "nodes.n%d" % (part_len - 1),
                        "size": 500
                    }
                }
            }
            branch_query = json.dumps(branch_search_body)
            search_body += '{"index": "'+self.config['es']['index']+'", "type": "metric_index", "search_type": "count"}' + "\n" + branch_query + "\n"

        branches = []
        leafs = {}
        with statsd.timer("graphite-api.search_series.es_search.query_duration"):
            ret = self.es.msearch(index=self.config['es']['index'], doc_type="metric_index", body=search_body)
            if len(ret['responses'][0]["hits"]["hits"]) > 0:
                for hit in ret['responses'][0]["hits"]["hits"]:
                    leaf = True
                    source = hit['_source']
                    if source['name'] not in leafs:
                        leafs[source['name']] = []
                    leafs[source['name']].append(RaintankMetric(source, leaf))
            if not query.leaves_only:
                if len(ret['responses'][1]['aggregations']['branches']['buckets']) > 0:
                    for agg in ret['responses'][1]['aggregations']['branches']['buckets']:
                        branches.append("%s.%s" % (".".join(parts[:-2]), agg['key']))

        return dict(leafs=leafs, branches=branches)

    def fetch_multi(self, nodes, start_time, end_time):
        with statsd.timer("graphite-api.fetch.raintank_query.query_duration"):
            data = self.fetch_from_tank(nodes, start_time, end_time)
        series = {}
        step = None
        with statsd.timer("graphite-api.fetch.unmarshal_raintank_resp.duration"):
            for path, arr in data.iteritems():
                series[path] = [p[0] for p in arr[1]]
                if step is None or step < arr[0]:
                    step = arr[0]

        time_info = ((start_time +step) - ((start_time + step) % step), end_time, step)
        return time_info, series

    def fetch_from_tank(self, nodes, start_time, end_time):
        params = {"target": [], "from": start_time, "to": end_time}
        maxDataPoints = g.get('maxDataPoints', None)
        if maxDataPoints is not None:
            params['maxDataPoints'] = maxDataPoints
        pathMap = {}
        for node in nodes:
            for metric in node.reader.metrics:
                target = metric.id
                if node.consolidateBy is not None:
                    target = "consolidateBy(%s,%s)" %(metric.id, node.consolidateBy)
                params['target'].append(target)
                pathMap[target] = metric.name

        url = "%sget" % self.config['tank']['url']
        headers = {
                'User-Agent': 'graphite_raintank'
        }
        resp = requests.get(url, params=params, headers=headers)
        logger.debug('fetch_from_tank', url=url, status_code=resp.status_code, body=resp.text)
        if resp.status_code == 400:
            raise Exception("metric-tank said: %s" % resp.text)
        if resp.status_code == 500:
            raise Exception("metric-tank internal server error")
        dataMap = {}
        mergeSet = {}
        for result in resp.json():
            path = pathMap[result['Target']]
            if path in dataMap:
                # flag the result as requiring merging
                if path not in mergeSet:
                    mergeSet[path] = [dataMap[path][1]]

                mergeSet[path].append(result['Datapoints'])
                
            else:
                dataMap[path] = [result['Interval'], result['Datapoints']]

        # we need to merge the datapoints.
        # metric-tank already fills will NULLS. so all we need to do is
        # scan all of the sets and use the first non null value, failing
        # back to using null.  This code assumes that all datapoints sets
        # returned from metric-tank have the same number of points (which they should)
        if len(mergeSet) > 0:
            for path, datapointList in mergeSet.iteritems():
                merged = []
                for i in range(0, len(datapointList[0])):
                    pos = 0
                    found = False
                    while not found and pos < len(datapointList):
                        if datapointList[pos][i][0] is not None:
                            merged.append(datapointList[pos][i])
                            found = True
                        pos += 1
                    if not found:
                        merged.append([None, datapointList[pos-1][i][1]])
                dataMap[path][1] = merged

        return dataMap

