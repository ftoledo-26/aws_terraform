#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install mysql-server -y

mysql << EOF

CREATE USER 'webuser'@'%' IDENTIFIED BY 'secret';
CREATE DATABASE webapp;
USE webapp;
CREATE TABLE usuario(
    ID INT PRIMARY KEY,
    NAME VARCHAR(255)
);
GRANT ALL PRIVILEGES ON webapp.* TO 'webuser'@'%';
FLUSH PRIVILEGES;


EOF
CNF=/etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" $CNF || true
systemctl restart mysql
# Borrar lineas 19,20,21 si no funciona