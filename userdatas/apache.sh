#!/bin/bash
yum install -y httpd autoconf libtool httpd-devel ca-certificates
wget https://dlcdn.apache.org/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.48-src.tar.gz
tar zxvf tomcat-connectors-1.2.48-src.tar.gz
cd tomcat-connectors-1.2.48-src/native/
apxs_location=`find / -name "apxs" -print`
./configure --with-apxs=$apxs_location
make
make install
\cp apache-2.0/mod_jk.so /usr/lib64/httpd/modules/mod_jk.so
echo `hostname -I` >> /var/www/html/index.html

cat << EOF > /etc/httpd/conf/workers.properties
worker.list=lb
worker.lb.type=lb
worker.lb.balance_workers=was1,was2

worker.was1.host=${nlb1}
worker.was1.port=8009
worker.was1.type=ajp13
worker.was1.secret=test
worker.was1.lbfactor=1

worker.was2.host=${nlb2}
worker.was2.port=8009
worker.was2.type=ajp13
worker.was2.secret=test
worker.was2.lbfactor=1
EOF

cat << EOF > /etc/httpd/conf.d/vhost.conf
LoadModule jk_module modules/mod_jk.so
<VirtualHost *:80>
    JKMount /*.jsp lb
</VirtualHost>

<IfModule jk_module>
  JkWorkersFile /etc/httpd/conf/workers.properties
  JkLogFile /var/log/httpd/mod_jk.log
  JkShmFile  /var/log/httpd/mod_jk.shm
  JkLogLevel info
  JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"
</IfModule>
EOF

systemctl start httpd
systemctl enable httpd
systemctl restart httpd
