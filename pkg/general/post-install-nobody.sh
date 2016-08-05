#!/usr/bin/env bash

# Create user if it doesn't exist
if ! id graphite > /dev/null 2>&1 ; then
	adduser --system --home /usr/share/python/graphite --no-create-home \
		--gid nobody --shell /bin/false \
		-c 'Graphite API' \
		graphite
fi

chown -R graphite:nobody /var/log/graphite
chown -R graphite:nobody /var/lib/graphite
