#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install -y apache2
sudo apt install -y libapache2-mod-security2 modsecurity-crs

sudo a2enmod security2

sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf

sudo mkdir -p /etc/modsecurity.d/activated_rules

sudo ln -s /usr/share/modsecurity-crs/base_rules/* /etc/modsecurity.d/activated_rules/

groupadd -r grupoDaw
useradd -r -s /usr/sbin/nologin -g grupoDaw usuarioDaw

sed -i 's/^export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=usuarioDaw/' /etc/apache2/envvars
sed -i 's/^export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=grupoDaw/' /etc/apache2/envvars

chown root:grupoDaw /var/www
chown -R usuarioDaw:grupoDaw /var/www/html

chmod 750 /var/www
chmod 750 /var/www/html

find /var/www/html -type d -exec chmod 750 {} \;
find /var/www/html -type f -exec chmod 640 {} \;

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

sudo sed -i 's/^ServerTokens .*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sudo sed -i 's/^ServerSignature .*/ServerSignature Off/' /etc/apache2/conf-available/security.conf

sudo sed -i 's/^Timeout .*/Timeout 60/' /etc/apache2/apache2.conf
sudo sed -i 's/^KeepAlive .*/KeepAlive On/' /etc/apache2/apache2.conf
sudo sed -i 's/^MaxKeepAliveRequests .*/MaxKeepAliveRequests 100/' /etc/apache2/apache2.conf
sudo sed -i 's/^KeepAliveTimeout .*/KeepAliveTimeout 5/' /etc/apache2/apache2.conf

sudo tee /etc/apache2/conf-available/hardening.conf > /dev/null <<EOF
FileETag None
LimitRequestBody 10485760

<IfModule mod_headers.c>
    Header unset Server
    Header unset X-Powered-By
    Header unset ETag
    
    Header set X-Content-Type-Options "nosniff"
    Header set X-Frame-Options "SAMEORIGIN"

    Header set Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; font-src 'self'; connect-src 'self'; frame-ancestors 'self'; form-action 'self'; base-uri 'self';"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
</IfModule>
EOF

sudo a2enconf hardening 
sudo apachectl configtest && sudo systemctl restart apache2
sudo systemctl enable apache2

sudo touch /var/log/apache2/modsec_audit.log
sudo chown root:adm /var/log/apache2/modsec_audit.log
sudo chmod 640 /var/log/apache2/modsec_audit.log
