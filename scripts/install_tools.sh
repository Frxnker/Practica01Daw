#!/bin/bash
set -ex
source .env
export DEBIAN_FRONTEND=noninteractive
apt update

# phpMyAdmin (respuestas automáticas al instalador)
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

# Usuario MySQL para entrar en phpMyAdmin/Adminer
mysql -u root <<< "DROP USER IF EXISTS '$APP_USER'@'%';"
mysql -u root <<< "CREATE USER '$APP_USER'@'%' IDENTIFIED BY '$APP_PASSWORD';"
mysql -u root <<< "GRANT ALL PRIVILEGES ON *.* TO '$APP_USER'@'%';"
mysql -u root <<< "FLUSH PRIVILEGES;"

# Adminer
mkdir -p /var/www/html/adminer
wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php -O /var/www/html/adminer/index.php

# GoAccess
apt install goaccess -y
mkdir -p /var/www/html/stats
goaccess /var/log/apache2/access.log -o /var/www/html/stats/index.html \
  --log-format=COMBINED --real-time-html --daemonize

# Proteger /stats con .htaccess
htpasswd -bc /etc/apache2/.htpasswd "$STATS_USERNAME" "$STATS_PASSWORD"
cp ../htaccess/.htaccess /var/www/html/stats/.htaccess

chown -R www-data:www-data /var/www/html
systemctl restart apache2