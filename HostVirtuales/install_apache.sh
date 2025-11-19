#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt upgrade -y
apt-get install apache2 -y

cat > /etc/apache2/sites-available/primero.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/primero
    ServerName primero-ivan.duckdns.org
</VirtualHost>
EOF

cat > /etc/apache2/sites-available/segundo.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/segundo
    ServerName segundo-ivan.duckdns.org
</VirtualHost>
EOF

a2ensite primero
a2ensite segundo
mkdir /var/www/primero
mkdir /var/www/segundo
systemctl reload apache2

cat > /var/www/primero/index.html << EOF
    <html>
        <body>
            <h1>
                Ivan
            </h1>
        </body>
    </html>
EOF

cat > /var/www/segundo/index.html << EOF
    <html>
        <body>
            <h1>
                Ivan Rios Raya
            </h1>
        </body>
    </html>
EOF