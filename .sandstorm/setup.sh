#!/bin/bash

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
unlink /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/sandstorm-php <<EOF
server {
    listen 8000 default_server;
    listen [::]:8000 default_server ipv6only=on;

    # Allow arbitrarily large bodies - Sandstorm can handle them, and requests
    # are authenticated already, so there's no reason for apps to add additional
    # limits by default.
    client_max_body_size 0;

    server_name localhost;
    root /opt/app/dokuwiki;
    index doku.php;
    location ~ /(data/|conf/|bin/|inc/|install.php) { deny all; }
    
    location / {
        try_files \$uri \$uri/ @dokuwiki;
    }
    location @dokuwiki {
        rewrite ^/_media/(.*) /lib/exe/fetch.php?media=\$1 last;
        rewrite ^/_detail/(.*) /lib/exe/detail.php?media=\$1 last;
        rewrite ^/_export/([^/]+)/(.*) /doku.php?do=export_\$1&id=\$2 last;
        rewrite ^/(.*) /doku.php?id=\$1&\$args last;
    }
    location ~ \\.php\$ {
        if (!-f \$request_filename) { return 404; }
        include fastcgi_params;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_param REDIRECT_STATUS 200;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    gzip off;

}
EOF
ln -s /etc/nginx/sites-available/sandstorm-php /etc/nginx/sites-enabled/sandstorm-php
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
# patch nginx conf to not bother trying to setuid, since we're not root
# also patch errors to go to stderr, and logs nowhere.
sed --in-place='' \
        --expression 's/^user www-data/#user www-data/' \
        --expression 's#^pid /run/nginx.pid#pid /var/run/nginx.pid#' \
        --expression 's/^\s*error_log.*/error_log stderr;/' \
        --expression 's/^\s*access_log.*/access_log off;/' \
        /etc/nginx/nginx.conf
# Add a conf snippet providing what sandstorm-http-bridge says the protocol is as var fe_https
cat > /etc/nginx/conf.d/50sandstorm.conf << EOF
    # Trust the sandstorm-http-bridge's X-Forwarded-Proto.
    map \$http_x_forwarded_proto \$fe_https {
        default "";
        https on;
    }
EOF
# Adjust fastcgi_params to use the patched fe_https
sed --in-place='' \
        --expression 's/^fastcgi_param *HTTPS.*$/fastcgi_param  HTTPS               \$fe_https if_not_empty;/' \
        /etc/nginx/fastcgi_params

mkdir -p /var/lib/dokuwiki/{conf,data,lib/plugins,lib/tpl}
chown -R vagrant.vagrant /var/lib/dokuwiki
