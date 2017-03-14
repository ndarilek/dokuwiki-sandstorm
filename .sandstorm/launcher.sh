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
rm -f /var/lib/dokuwiki/conf/conf

if [ ! -e /var/lib/dokuwiki/data ]; then
  echo Adding data.
  rsync -a /opt/app/dokuwiki/data.orig/ /var/lib/dokuwiki/data
fi
rm -f /var/lib/dokuwiki/data/data

rsync -a /opt/app/dokuwiki/lib/plugins.orig/ /var/lib/dokuwiki/lib/plugins
rm -f /var/lib/dokuwiki/lib/plugins/plugins
rsync -a /opt/app/plugin/ /var/lib/dokuwiki/lib/plugins/sandstorm

if [ ! -e /var/lib/dokuwiki/lib/tpl ]; then
  echo Adding templates.
  rsync -a /opt/app/dokuwiki/lib/tpl.orig/ /var/lib/dokuwiki/lib/tpl
fi
rm -f /var/lib/dokuwiki/lib/tpl/tpl

cd /var/lib/dokuwiki
grep -Ev '^($|#)' /opt/app/dokuwiki/data.orig/deleted.files | xargs -n 1 rm -vrf

cp /opt/app/acl.auth.php /var/lib/dokuwiki/conf

function cleanup()
{
    local data_path="$1"        # full path to data directory of wiki
    local retention_days="$2"   # number of days after which old files are to be removed

    # purge files older than ${retention_days} days from attic and media_attic (old revisions)
    find "${data_path}"/{media_,}attic/ -type f -mtime +${retention_days} -delete

    # remove stale lock files (files which are 1-2 days old)
    find "${data_path}"/locks/ -name '*.lock' -type f -mtime +1 -delete

    # remove empty directories
    find "${data_path}"/{attic,cache,index,locks,media,media_attic,media_meta,meta,pages,tmp}/ \
        -mindepth 1 -type d -empty -delete

    # remove files older than ${retention_days} days from the cache
    if [ ! -z "$(ls -A $data_path/cache)" ]; then
        find "${data_path}"/cache/?/ -type f -mtime +${retention_days} -delete
    fi
}

cleanup /var/lib/dokuwiki/data    30

# Start nginx.
/usr/sbin/nginx -c /opt/app/.sandstorm/service-config/nginx.conf -g "daemon off;"
