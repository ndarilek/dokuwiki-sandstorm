#!/bin/bash

# Create a bunch of folders under the clean /var that php and nginx expect to exist
mkdir -p /var/lib/nginx
mkdir -p /var/lib/php5/sessions
mkdir -p /var/log
mkdir -p /var/log/nginx
mkdir -p /var/www
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run

# Spawn php
/usr/sbin/php5-fpm --nodaemonize --fpm-config /etc/php5/fpm/php-fpm.conf &
# Wait until php have bound its socket, indicating readiness
while [ ! -e /var/run/php5-fpm.sock ] ; do
    echo "waiting for php5-fpm to be available at /var/run/php5-fpm.sock"
    sleep .2
done

rsync -a /opt/app/dokuwiki/ /var/www

if [ ! -f /var/www/conf/local.php ]; then
  cp /opt/app/local.php /var/www/conf
fi

# Start nginx.
/usr/sbin/nginx -g "daemon off;"
