#!/bin/bash

read -s -p "Your mysql root password: " mysql_root_passwd
echo
read -s -p "Comfirm:  " mysql_root_passwd_confirm
echo

until [ $mysql_root_passwd == $mysql_root_passwd_confirm && $mysql_root_passwd != '' ]
do
	echo "The password and the confirmation you typed do not match."
	read -s -p "Retype your mysql root password: " mysql_root_passwd
	echo
	read -s -p "Comfirm:  " mysql_root_passwd_confirm
	echo
done


apt update
apt upgrade -y

systemctl stop ufw
systemctl disable ufw

apt install nginx -y
systemctl start nginx
systemctl enable nginx

apt install mysql-server -y

mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${mysql_root_passwd}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

add-apt-repository universe
apt install php-fpm php-mysql -y

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

systemctl restart nginx


cd /var/www/html/
cat > info.php << "EOF"
<?php
phpinfo();
EOF

echo Done!
