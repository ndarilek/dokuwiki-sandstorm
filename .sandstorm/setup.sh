#!/bin/bash

# When you change this file, you must take manual action. Read this doc:
# - https://docs.sandstorm.io/en/latest/vagrant-spk/customizing/#setupsh

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx php5-fpm php5-cli php5-curl git php5-dev libleveldb-dev
cd /usr/local/src
git clone https://github.com/reeze/php-leveldb.git
cd php-leveldb
phpize
./configure
make
make install
cp /opt/app/leveldb.ini /etc/php5/mods-available
php5enmod leveldb
service nginx stop
service php5-fpm stop
systemctl disable nginx
systemctl disable php5-fpm
# patch /etc/php5/fpm/pool.d/www.conf to not change uid/gid to www-data
sed --in-place='' \
        --expression='s/^listen.owner = www-data/#listen.owner = www-data/' \
        --expression='s/^listen.group = www-data/#listen.group = www-data/' \
        --expression='s/^user = www-data/#user = www-data/' \
        --expression='s/^group = www-data/#group = www-data/' \
        /etc/php5/fpm/pool.d/www.conf
# patch /etc/php5/fpm/php-fpm.conf to not have a pidfile
sed --in-place='' \
        --expression='s/^pid =/#pid =/' \
        /etc/php5/fpm/php-fpm.conf
# patch /etc/php5/fpm/pool.d/www.conf to no clear environment variables
# so we can pass in SANDSTORM=1 to apps
sed --in-place='' \
        --expression='s/^;clear_env = no/clear_env=no/' \
        /etc/php5/fpm/pool.d/www.conf
# Adjust fastcgi_params to use the patched fe_https
sed --in-place='' \
        --expression 's/^fastcgi_param *HTTPS.*$/fastcgi_param  HTTPS               \$fe_https if_not_empty;/' \
        /etc/nginx/fastcgi_params

mkdir -p /var/lib/dokuwiki/{conf,data,lib/plugins,lib/tpl}
chown -R vagrant.vagrant /var/lib/dokuwiki
