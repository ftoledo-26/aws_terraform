#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install apache2 -y

sudo a2dismod status
sudo a2dismod info
sudo a2dismod autoindex
sudo a2dismod userdir
sudo a2dismod cgi
sudo a2dismod cgid
sudo a2dismod proxy
sudo a2dismod negotiation
sudo a2dismod include

systemctl restart apache2

cat > /etc/apache2/conf-available/ocultInfo.conf << EOF
ServerTokens Prod
ServerSignature Off
EOF

a2enconf ocultInfo
systemctl restart apache2