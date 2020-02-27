#!/bin/bash
yum -y install epel-release
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum-config-manager --disable remi-php54
yum-config-manager --enable remi-php73
yum -y install httpd mariadb mariadb-server php php-common php-mysql php-gd php-xml php-mbstring php-mcrypt wget

systemctl start httpd.service
systemctl enable httpd.service
systemctl start mariadb
systemctl enable mariadb.service

mysql -u root <<-EOF
create database wordpress;
CREATE USER wordpressuser@localhost IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
EOF

#mysql_secure_installation
#echo -e "\n\npassword\password\n\n\nn\n\n " | mysql_secure_installation 2>/dev/null
mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('password') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

cd ~
wget http://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
cp -R ~/wordpress/* /var/www/html/
mkdir /var/www/html/wp-content/uploads

cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "/DB_HOST/s/'[^']*'/'localhost'/2" /var/www/html/wp-config.php
sed -i "/DB_NAME/s/'[^']*'/'wordpress'/2" /var/www/html/wp-config.php
sed -i "/DB_USER/s/'[^']*'/'wordpressuser'/2" /var/www/html/wp-config.php
sed -i "/DB_PASSWORD/s/'[^']*'/'password'/2" /var/www/html/wp-config.php
chown -R apache:apache /var/www/html/*

firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --add-service=https
firewall-cmd --zone=public --permanent --add-service=https
