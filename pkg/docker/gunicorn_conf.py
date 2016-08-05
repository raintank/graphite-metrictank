import os
import multiprocessing

bind = "0.0.0.0:8080"
worker_class = "eventlet"
workers = multiprocessing.cpu_count()

for name,value in os.environ.items():
	if name == 'GRAPHITE_BIND':
     bind = value
  if name == 'GRAPHITE_WORKERS':
    workers = value
