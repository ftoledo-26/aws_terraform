#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

# Actualizar sistema e instalar Apache
apt update
apt install -y apache2

# Deshabilitar módulos innecesarios de Apache
sudo a2dismod status
sudo a2dismod info
sudo a2dismod -f autoindex
sudo a2dismod userdir
sudo a2dismod cgi
sudo a2dismod cgid
sudo a2dismod proxy
sudo a2dismod -f negotiation
sudo a2dismod include

sudo a2enmod headers
# Reiniciar Apache tras cambios de módulos
systemctl restart apache2

# Hardening: ocultar información de Apache
sudo tee /etc/apache2/conf-available/ocultInfo.conf > /dev/null <<EOF
ServerTokens Prod
ServerSignature Off

<IfModule mod_headers.c>
    Header always unset X-Powered-By
    Header set Server "Apache"
</IfModule>
EOF

# Habilitar configuración y aplicar cambios
a2enconf ocultInfo
apachectl configtest
systemctl reload apache2