#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1


apt update
apt install apache2 -y
hostnamectl set-hostname frontend.ejercicio.clase.com
a2enmod proxy # Habilitar el módulo proxy
a2enmod proxy_http # Habilitar el módulo proxy_http

a2dissite 000-default.conf
systemctl restart apache2

cat > /etc/apache2/sites-available/001-frontend.conf << EOF
<VirtualHost *:80>
    ProxyPass "/api/" "http://${backend_ip}/"
    ProxyPassReverse "/api/" "http://${backend_ip}/"
    
    DocumentRoot /var/www/html
</VirtualHost>
EOF
mkdir -p /var/www/html
cat > /var/www/html/index.html << EOF
<html>
    <body>
        <h1>
            Frontend Ejercicio Clase
        </h1>
        <p> Accede a la API en <a href="/api/">/api/</a> </p>
    </body>
</html>
EOF
a2ensite 001-frontend.conf
systemctl reload apache2

systemctl restart apache2