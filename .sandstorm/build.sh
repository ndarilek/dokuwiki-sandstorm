#!/bin/bash
# Checks if there's a composer.json, and if so, installs/runs composer.

set -euo pipefail

cd /opt/app/dokuwiki

if [ -f /opt/app/dokuwiki/composer.json ] ; then
    if [ ! -f composer.phar ] ; then
        curl -sS https://getcomposer.org/installer | php
    fi
    php composer.phar install
fi

rsync -a /opt/app/plugin/ /opt/app/dokuwiki/lib/plugins/sandstorm/

for p in /opt/app/dokuwiki/{conf,data,lib/plugins,lib/tpl}; do
  if [ ! -e $p.orig ]; then
    mv $p $p.orig
  fi
  if [ -e $p ]; then
    rm -rf $p
  fi
done

ln -sf /var/lib/dokuwiki/conf /opt/app/dokuwiki/conf
ln -sf /var/lib/dokuwiki/data /opt/app/dokuwiki/data
ln -sf /var/lib/dokuwiki/lib/plugins /opt/app/dokuwiki/lib/plugins
ln -sf /var/lib/dokuwiki/lib/tpl /opt/app/dokuwiki/lib/tpl
