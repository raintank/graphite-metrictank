FROM ubuntu:16.04
 
RUN apt-get update && apt-get install -y libcairo2 libffi6 python
RUN mkdir -p /etc/graphite-metrictank

COPY docker/gunicorn_conf.py /etc/graphite-metrictank
COPY common/graphite-metrictank/graphite-metrictank.yaml /etc/graphite-metrictank/graphite-metrictank.yaml

COPY build/ubuntu/xenial/usr /usr
COPY docker/entrypoint.sh /usr/local/bin/

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
