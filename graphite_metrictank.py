import time
import requests
from graphite_api.intervals import Interval, IntervalSet
from graphite_api.node import LeafNode, BranchNode
from flask import g
import structlog
logger = structlog.get_logger('graphite_api')
import platform
from werkzeug.exceptions import HTTPException
import msgpack
import math

class MetrictankException(HTTPException):
    def __init__(self, code=500, description="Metrictank Error"):
        super(MetrictankException, self).__init__(description=description, response=None)
        self.code = code

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

        self.http_session = requests.Session()
        self.http_session.headers.update({"User-Agent": "graphite_metrictank"})

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
                'X-Org-Id': "%d" % g.org,
        }
        url = "%smetrics/find" % self.config['tank']['url']
        with statsd.timer("graphite-api.%s.find.query_duration" % hostname):
            try:
                resp = self.http_session.get(url, params=params, headers=headers)
            except Exception as e:
                logger.error("find_nodes", url=url, error=e.message)
                raise MetrictankException(code=503, description="metric-tank service unavailable")

        logger.debug('find_nodes', url=url, status_code=resp.status_code, body=resp.text)
        if resp.status_code >= 500:
            logger.error("find_nodes", url=url, status_code=resp.status_code, body=resp.text)
            if resp.status_code == 500:
                raise MetrictankException(500, "metric-tank internal server error")
            elif resp.status_code == 502:
                raise MetrictankException(502, "metric-tank bad gateway")
            elif resp.status_code == 503:
                raise MetrictankException(503, "metric-tank service unavailable")
            elif resp.status_code == 504:
                raise MetrictankException(504, "metric-tank gateway timeout")
            else:
                raise MetrictankException(resp.status_code, resp.text)

        if resp.status_code >= 400:
            raise MetrictankException(resp.status_code, resp.text)
        
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
        params = {"target": [], "from": start_time, "to": end_time, "format": "msgp"}
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

        url = "%sget" % self.config['tank']['url']
        headers = {
                'X-Org-Id': "%d" % g.org,
        }
        with statsd.timer("graphite-api.%s.fetch.raintank_query.query_duration" % hostname):
            try:
                resp = self.http_session.post(url, data=params, headers=headers)
            except Exception as e:
                logger.error("fetch_from_tank", url=url, error=e.message)
                raise MetrictankException(code=503, description="metric-tank service unavailable")
                
        logger.debug('fetch_from_tank', url=url, status_code=resp.status_code, body=resp.text)
        if resp.status_code >= 500:
            logger.error("fetch_from_tank", url=url, status_code=resp.status_code, body=resp.text)
            if resp.status_code == 500:
                raise MetrictankException(500, "metric-tank internal server error")
            elif resp.status_code == 502:
                raise MetrictankException(502, "metric-tank bad gateway")
            elif resp.status_code == 503:
                raise MetrictankException(503, "metric-tank service unavailable")
            elif resp.status_code == 504:
                raise MetrictankException(504, "metric-tank gateway timeout")
            else:
                raise MetrictankException(resp.status_code, resp.text)

        if resp.status_code >= 400:
            raise MetrictankException(resp.status_code, resp.text)

        series = {}
        time_info = None
        with statsd.timer("graphite-api.%s.fetch.unmarshal_raintank_resp.duration" % hostname):
            for result in msgpack.unpackb(resp.content):
                path = pathMap[result["Target"]]
                series[path] = [p["Val"] if not math.isnan(p["Val"]) else None for p in result["Datapoints"]]
                if time_info is None:
                    if len(result["Datapoints"]) == 0:
                        time_info = (start_time, end_time, result["Interval"])
                    else:
                        first = result["Datapoints"][0]["Ts"]
                        last = result["Datapoints"][-1]["Ts"]
                        step = result["Interval"]
                        time_info = (first, last+step, step)

        return time_info, series
