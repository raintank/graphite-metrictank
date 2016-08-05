import multiprocessing

bind = "0.0.0.0:8080"
errorlog = "/var/log/graphite/graphite-metrictank.log"
worker_class = "eventlet"
workers = multiprocessing.cpu_count()