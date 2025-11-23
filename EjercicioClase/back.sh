#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install apache2 -y
apt install php libapache2-mod-php php-mysql -y
