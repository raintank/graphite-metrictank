import re
import time
import struct
import requests
from graphite_api.intervals import Interval, IntervalSet
from graphite_api.node import LeafNode, BranchNode
from flask import g
import structlog
logger = structlog.get_logger('graphite_api')
import json
import hashlib
import platform

class NullStatsd():
    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        pass

    def timer(self, key, val=None):
        return self

    def timing(self, key, val):
        pass

    def incr(self, key, count=None, rate=None):
        pass

try:
    from graphite_api.app import app
    statsd = app.statsd
    assert statsd is not None
except:
    statsd = NullStatsd()

class NullCache():

    def set(self, *args, **kwargs):
        pass

    def get(self, *args, **kwargs):
        return None


try:
    from graphite_api.app import app
    cache = app.cache
    assert cache is not None
except:
    cache = NullCache()

hostname = platform.node()

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
    def __init__(self, path):
        self.path = path

    def get_intervals(self):
        return IntervalSet([Interval(0, time.time())])

    def fetch(self, startTime, endTime):
        pass

class RaintankFinder(object):
    __fetch_multi__ = "raintank"

    def __init__(self, config):
        cfg = config.get('raintank', {})
        rt = cfg.get('tank', {})
        self.config = {
            "tank": {
               "url": rt.get('url', 'http://localhost:6060/')
            },
            "cache_ttl": rt.get("cache_ttl", 60),
        }
        if not self.config["tank"]["url"].endswith("/"):
            self.config["tank"]["url"] += "/"
            
        logger.info("initialize RaintankFinder", config=self.config)

    def find_nodes(self, query):
        pattern = query.pattern
        if query.pattern.startswith("litmus"):
            pattern = query.pattern.replace("litmus", "worldping", 1)

        params = {
            "query": pattern, 
            "from": query.startTime, 
            "until": query.endTime,
            "format": "completer",
        }
        headers = {
                'User-Agent': 'graphite_raintank',
                'X-Org-Id': "%d" % g.org,
        }
        url = "%smetrics/find" % self.config['tank']['url']
        with statsd.timer("graphite-api.%s.find.query_duration" % hostname):
            resp = requests.get(url, params=params, headers=headers)

        logger.debug('find_nodes', url=url, status_code=resp.status_code, body=resp.text)

        if resp.status_code >= 400 and resp.status_code < 500:
            raise Exception("bad request: %s" % resp.text)
        if resp.status_code == 500:
            raise Exception("metric-tank internal server error")
        if resp.status_code == 502:
            raise Exception("metric-tank bad gateway")
        if resp.status_code == 503:
            raise Exception("metric-tank service unavailable")
        if resp.status_code == 504:
            raise Exception("metric-tank gateway timeout")

        data = resp.json()
        if "metrics" not in data:
            raise Exception("invalid response from metrictank.")

        for metric in data["metrics"]:
            if metric["is_leaf"] == "1":
                path = metric["path"]
                if query.pattern != pattern:
                    path = metric["path"].replace("worldping", "litmus", 1)
                yield RaintankLeafNode(path, RaintankReader(metric["path"]))
            else:
                path = metric["path"]
                if query.pattern != pattern:
                    path = metric["path"].replace("worldping", "litmus", 1)
                yield BranchNode(path)


    def fetch_multi(self, nodes, start_time, end_time):
        data = self.fetch_from_tank(nodes, start_time, end_time)
        series = {}
        step = None
        for path, arr in data.iteritems():
            series[path] = [p[0] for p in arr[1]]
            if step is None or step < arr[0]:
                step = arr[0]

        time_info = ((start_time +step) - ((start_time + step) % step), end_time, step)
        return time_info, series

    def fetch_multi(self, nodes, start_time, end_time):
        params = {"target": [], "from": start_time, "to": end_time}
        maxDataPoints = g.get('maxDataPoints', None)
        if maxDataPoints is not None:
            params['maxDataPoints'] = maxDataPoints
        pathMap = {}
        for node in nodes:     
            target = node.reader.path
            if node.consolidateBy is not None:
                target = "consolidateBy(%s,%s)" %(node.reader.path, node.consolidateBy)
            params['target'].append(target)
            pathMap[target] = node.path

        url = "%srender" % self.config['tank']['url']
        headers = {
                'User-Agent': 'graphite_raintank',
                'X-Org-Id': "%d" % g.org,
        }
        with statsd.timer("graphite-api.%s.fetch.raintank_query.query_duration" % hostname):
            resp = requests.post(url, data=params, headers=headers)
        logger.debug('fetch_from_tank', url=url, status_code=resp.status_code, body=resp.text)
        if resp.status_code >= 400 and resp.status_code < 500:
            raise Exception("metric-tank said: %s" % resp.text)
        if resp.status_code == 500:
            raise Exception("metric-tank internal server error")
        if resp.status_code == 502:
            raise Exception("metric-tank bad gateway")
        if resp.status_code == 503:
            raise Exception("metric-tank service unavailable")
        if resp.status_code == 504:
            raise Exception("metric-tank gateway timeout")

        series = {}
        time_info = None
        with statsd.timer("graphite-api.%s.fetch.unmarshal_raintank_resp.duration" % hostname):
            for result in resp.json():
                path = pathMap[result["target"]]
                series[path] = [p[0] for p in result["datapoints"]]
                if time_info is None:
                    if len(result["datapoints"]) == 0:
                        time_info = (start_time, end_time, end_time-start_time)
                    else:
                        first = result["datapoints"][0][1]
                        last = result["datapoints"][-1][1]
                        if len(result["datapoints"]) == 1:
                            step = end_time-start_time
                        else:
                            step = result["datapoints"][1][1] - result["datapoints"][0][1]
                        time_info = (first, last, step)

        return time_info, series
