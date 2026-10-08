#!/bin/bash

# Mostramos los comandos que se ejecutan y paramos si hay algún error
set -ex

# Nos situamos en el directorio del script para que las rutas relativas funcionen
cd "$(dirname "$0")"

# Actualizamos los repositorios y los paquetes
apt update
apt upgrade -y

# Instalamos el servidor web Apache
apt install apache2 -y

# Habilitamos el módulo rewrite
a2enmod rewrite

# Instalamos PHP y los módulos para Apache y MySQL
apt install php libapache2-mod-php php-mysql -y

# Copiamos nuestro archivo de configuración del VirtualHost
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf

# Reiniciamos Apache para aplicar los cambios
systemctl restart apache2

# Instalamos MySQL Server
apt install mysql-server -y

# Copiamos el script de prueba de PHP y eliminamos la página por defecto
cp ../php/index.php /var/www/html/index.php
rm -f /var/www/html/index.html

# Asignamos el propietario y el grupo de Apache al directorio web
chown -R www-data:www-data /var/www/html
