#!/bin/bash

# Mostramos los comandos que se ejecutan y paramos si hay algún error
set -ex

# Nos situamos en el directorio del script para que las rutas relativas funcionen
cd "$(dirname "$0")"

# Importamos las variables de entorno
source .env

# Actualizamos los repositorios
apt update

#-----------------------------------------------------------------------
# phpMyAdmin
#-----------------------------------------------------------------------

# Configuramos las respuestas para una instalación desatendida
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections

# Instalamos phpMyAdmin y sus dependencias
apt install phpmyadmin php-mbstring php-zip php-gd php-curl -y

#-----------------------------------------------------------------------
# Adminer
#-----------------------------------------------------------------------

mkdir -p /var/www/html/adminer
wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php -O /var/www/html/adminer/index.php
chown -R www-data:www-data /var/www/html/adminer

#-----------------------------------------------------------------------
# Usuario y base de datos de MySQL
#-----------------------------------------------------------------------

mysql -u root <<< "CREATE DATABASE IF NOT EXISTS $DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS '$DB_USER'@'%'"
mysql -u root <<< "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"

#-----------------------------------------------------------------------
# GoAccess
#-----------------------------------------------------------------------

apt install goaccess -y

# Generamos el informe en tiempo real como un proceso en segundo plano
mkdir -p /var/www/html/stats
goaccess /var/log/apache2/access.log -o /var/www/html/stats/index.html --log-format=COMBINED --real-time-html --daemonize

#-----------------------------------------------------------------------
# Control de acceso a /stats con .htaccess
#-----------------------------------------------------------------------

# Creamos el archivo de contraseñas
htpasswd -bc /etc/apache2/.htpasswd "$STATS_USERNAME" "$STATS_PASSWORD"

# Copiamos el .htaccess al directorio de estadísticas
cp ../htaccess/.htaccess /var/www/html/stats/.htaccess

chown -R www-data:www-data /var/www/html/stats

# Reiniciamos Apache
systemctl restart apache2
