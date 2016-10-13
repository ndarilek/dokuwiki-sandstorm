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

mkdir -p /var/lib/dokuwiki/lib/plugins/sandstorm

if [ ! -e /var/lib/dokuwiki/conf/local.php ]; then
  echo Adding new configuration.
  rsync -a /opt/app/dokuwiki/conf.orig/ /var/lib/dokuwiki/conf
  cp /opt/app/local.php /var/lib/dokuwiki/conf
fi

if [ ! -e /var/lib/dokuwiki/data ]; then
  echo Adding data.
  rsync -a /opt/app/dokuwiki/data.orig/ /var/lib/dokuwiki/data
fi

rsync -a /opt/app/dokuwiki/lib/plugins.orig/ /var/lib/dokuwiki/lib/plugins
rsync -a /opt/app/plugin/ /var/lib/dokuwiki/lib/plugins/sandstorm

if [ ! -e /var/lib/dokuwiki/lib/tpl ]; then
  echo Adding templates.
  rsync -a /opt/app/dokuwiki/lib/tpl.orig/ /var/lib/dokuwiki/lib/tpl
fi

cd /var/lib/dokuwiki
grep -Ev '^($|#)' /opt/app/dokuwiki/data.orig/deleted.files | xargs -n 1 rm -vrf

# Start nginx.
/usr/sbin/nginx -c /opt/app/.sandstorm/service-config/nginx.conf -g "daemon off;"
