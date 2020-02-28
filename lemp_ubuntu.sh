#!/bin/bash

apt update
apt upgrade

apt install nginx
systemctl stop ufw
systemctl stop iptable
systemctl disable ufw
systemctl disable iptable

apt install mysql-server
mysql_secure_installation

echo "SELECT user,authentication_string,plugin,host FROM mysql.user;"
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
echo "FLUSH PRIVILEGES;"

mysql

add-apt-repository universe
apt install php-fpm php-mysql

cd /etc/nginx/sites-enabled/
unlink default

cd /etc/nginx/sites-available/
cat > test.conf << "EOF"
server {
        listen 80;
        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;
#        server_name example.com;

        location / {
                try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}
EOF

ln -s /etc/nginx/sites-available/test.conf /etc/nginx/sites-enabled/

systemctl reload nginx


cd /var/www/html/
cat > info.php << "EOF"
<?php
phpinfo();
EOF

echo Done!