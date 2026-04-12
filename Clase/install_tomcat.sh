#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt install -y needrestart


sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf

apt install -y openjdk-17-jdk wget

groupadd --system tomcat
useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

TOMCAT_VERSION=$(wget -qO- https://archive.apache.org/dist/tomcat/tomcat-11/ | grep -oP '(?<=v)[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1)
echo "Versión de Tomcat detectada: ${TOMCAT_VERSION}"
wget https://archive.apache.org/dist/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp
echo "Descarga completada: $(ls -lh /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz)"
mkdir -p /opt/tomcat
tar -xzf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat --strip-components=1

chown -R tomcat:tomcat /opt/tomcat
chmod -R 755 /opt/tomcat


sed -i '/<Valve /,/\/>/ s|<Valve|<!--<Valve|; /<Valve /,/\/>/ s|/>|/>-->|' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/<Valve /,/\/>/ s|<Valve|<!--<Valve|; /<Valve /,/\/>/ s|/>|/>-->|' /opt/tomcat/webapps/host-manager/META-INF/context.xml

cat > /opt/tomcat/conf/tomcat-users.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
    <role rolename="manager-gui"/>
    <role rolename="admin-gui"/>
    <user username="admin" password="admin" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOF

cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat 11
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_HOME=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat