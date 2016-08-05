#!/usr/bin/env bash

# Create user if it doesn't exist
if ! id graphite > /dev/null 2>&1 ; then
	adduser --system --home /usr/share/python/graphite --no-create-home \
		--ingroup nogroup --disabled-password --shell /bin/false \
		--gecos 'Graphite API' \
		graphite
fi

chown -R graphite:nogroup /var/log/graphite
chown -R graphite:nogroup /var/lib/graphite
