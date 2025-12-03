#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install -y apache2
apt install -y php libapache2-mod-php

cd /etc/apache2/sites-available
cat > /etc/apache2/sites-available/semitransparent.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/semitransparent
    ServerName semitransparent.com
</VirtualHost>
EOF

mkdir -p /var/www/semitransparent
cat > /var/www/semitransparent/index.php << EOF
<?php
phpinfo();
?>
EOF

a2dissite 000-default
a2ensite semitransparent
systemctl restart apache2