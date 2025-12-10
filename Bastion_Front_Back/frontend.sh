#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install apache2 -y

a2enmod proxy
a2enmod proxy_http

a2dissite 000-default.conf
systemctl restart apache2

cat > /etc/apache2/sites-available/001-frontend.conf << EOF
<VirtualHost *:80>
    ServerName frontend.prueba.com
    ServerAlias www.frontend.prueba.com

    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ProxyPass "/api/" "http://${backend_ip}/"
    ProxyPassReverse "/api/" "http://${backend_ip}/"
</VirtualHost>
EOF
a2ensite 001-frontend.conf

mkdir -p /var/www/html
cat > /var/www/html/index.html << EOF
<html>
    <body>
        <h1>
            Frontend Bastion
        </h1>
        <p> Accede a la API en <a href="/api/">/api/
</a> </p>
    </body>
</html>
EOF
systemctl restart apache2
systemctl reload apache2


#sudo apt update
#sudo apt install certbot python3-certbot-apache -y
#sudo certbot --apache -d frontend.prueba.com -d www.frontend.prueba.com
#sudo systemctl status certbot.timer
#echo Listen 8008 > /etc/apache2/ports.conf
