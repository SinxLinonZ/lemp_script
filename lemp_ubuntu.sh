#!/bin/bash


#-----------------------------
#   define functions
#-----------------------------
update_system() {
	apt update
	apt upgrade -y
}

ufw_active() {
	systemctl start ufw
	systemctl enable ufw
	ufw enable
}

ufw_shutdown() {
	systemctl stop ufw
	systemctl disable ufw
}

ufw_open_port() {
	for port in $*
	do
		ufw allow $port
	done
}


#DELETE FROM mysql.user WHERE User='';
#DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
#DROP DATABASE test;
#DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
db_mysql_init() {
	if [[ $1 == 'n' && $2 == 'y' ]]
	then
		mysql_host="UPDATE user SET host = '%' WHERE user = 'root';"
		mysql_P="ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${db_root_passwd}';"
	elif [[ $1 == 'n' && $2 == 'n' ]]
	then
		mysql_P="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${db_root_passwd}';"
	fi
}

db_mysql_set() {
	mysql << EOF
${mysql_host}
FLUSH PRIVILEGES;
${mysql_P}
FLUSH PRIVILEGES;
EOF
}

db_mariadb_init() {
	if [[ $1 == 'n' && $2 == 'y' ]]
	then
		mariadb_host="UPDATE user SET host = '%' WHERE user = 'root';"
		mariadb_Pw="UPDATE mysql.user SET authentication_string = PASSWORD('${db_root_passwd}') WHERE User = 'root';"
		mariadb_Pl="UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root';"
	elif [[ $1 == 'n' && $2 == 'n' ]]
	then
		mariadb_Pw="UPDATE mysql.user SET authentication_string = PASSWORD('${db_root_passwd}') WHERE User = 'root';"
		mariadb_Pl="UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root';"
	fi
}

db_mariadb_set() {
	mysql << EOF
${mariadb_host}
FLUSH PRIVILEGES;
${mariadb_Pw}
${mariadb_Pl}
FLUSH PRIVILEGES;
EOF
}


#-----------------------------
#   check if root/sudo
#-----------------------------
if [ "$EUID" -ne 0 ]
then
	echo -e "\033[31m[Error] Please run as root\033[0m"
	exit
fi


#-----------------------------
#   init variables
#-----------------------------
mysql_host=''
mysql_P=''
mariadb_host=''
mariadb_Pw=''
mariadb_Pl=''


#-----------------------------
#   set database software
#-----------------------------
db_type=''

until [[ $db_type == 'mysql' || $db_type == '1' || $db_type == 'mariadb' || $db_type == '2' ]]
do
	echo "The following databse software can be installed."
	echo "1) MySQL"
	echo "2) mariaDB"
	read -p "Which databse software do you want to be installed: " db_type

	db_type=$(echo $db_type | tr 'A-Z' 'a-z')

	if [[ $db_type == 'mysql' || $db_type == '1' ]]
	then
		echo
		echo -e "\033[32m[INFO] MySQL will be installed\033[0m"

	elif [[ $db_type == 'mariadb' || $db_type == '2' ]]
	then
		echo
		echo -e "\033[32m[INFO] mariaDB will be installed\033[0m"

	else
		echo
		echo -e "\033[31m[Error] Selection error. Please reselect your database software\033[0m"
	fi
done
echo


#-----------------------------
#   if use unix_socket
#-----------------------------
db_if_unix_socket='NULL'

until [[ $db_if_unix_socket == '' || $db_if_unix_socket == 'y' || $db_if_unix_socket == 'n' ]]
do
	read -p "Use unix_socket for authentication [y/N] " db_if_unix_socket

	db_if_unix_socket=$(echo $db_if_unix_socket | tr 'A-Z' 'a-z')

	if [[ $db_if_unix_socket != '' && $db_if_unix_socket != 'y' && $db_if_unix_socket != 'n' ]]
	then
		echo -e "\033[31m[Error] Selection error.\033[0m"
	fi

	if [[ $db_if_unix_socket == '' ]]
	then
		db_if_unix_socket='n'
	fi
done
echo


#-----------------------------
#   set database root password
#-----------------------------
if [[ $db_if_unix_socket == 'n' ]]
then
	db_root_passwd=''
	db_root_passwd_confirm=''

	until [[ $db_root_passwd == $db_root_passwd_confirm && $db_root_passwd != '' ]]
	do
		read -s -p "Your database root password: " db_root_passwd
		echo
		read -s -p "Comfirm:  " db_root_passwd_confirm
		echo

		if [[ $db_root_passwd != $db_root_passwd_confirm ]]
		then
			echo -e "\033[31m[Error] The password and the confirmation you typed do not match.\033[0m"
			echo -e "\033[31mPlease retype your database root password\033[0m"
		fi

		if [[ $db_root_passwd == '' ]]
		then
			echo -e "\033[31m[Error] Empty password.\033[0m"
			echo -e "\033[31mPlease retype your database root password\033[0m"
		fi
	done
fi
echo


#-----------------------------
#   database remote access
#-----------------------------
if [[ $db_if_unix_socket == 'n' ]]
then
	db_if_remote_access='NULL'

	until [[ $db_if_remote_access == '' || $db_if_remote_access == 'y' || $db_if_remote_access == 'n' ]]
	do
		read -p "Enable remote access to database [y/N] " db_if_remote_access

		db_if_remote_access=$(echo $db_if_remote_access | tr 'A-Z' 'a-z')

		if [[ $db_if_remote_access != '' && $db_if_remote_access != 'y' && $db_if_remote_access != 'n' ]]
		then
			echo -e "\033[31m[Error] Selection error.\033[0m"
		fi

		if [[ $db_if_remote_access == '' ]]
		then
			db_if_remote_access='n'
		fi
	done
fi
echo


#-----------------------------
#   if update system
#-----------------------------
sys_if_update_system='NULL'

until [[ $sys_if_update_system == '' || $sys_if_update_system == 'y' || $sys_if_update_system == 'n' ]]
do
	read -p "Update your system before deploying LEMP [Y/n] " sys_if_update_system

	sys_if_update_system=$(echo $sys_if_update_system | tr 'A-Z' 'a-z')

	if [[ $sys_if_update_system != '' && $sys_if_update_system != 'y' && $sys_if_update_system != 'n' ]]
	then
		echo -e "\033[31m[Error] Selection error.\033[0m"
	fi

	if [[ $sys_if_update_system == '' ]]
	then
		sys_if_update_system='y'
	fi
done
echo


#-----------------------------
#   if use ufw
#-----------------------------
sys_if_use_ufw='NULL'

until [[ $sys_if_use_ufw == '' || $sys_if_use_ufw == 'y' || $sys_if_use_ufw == 'n' ]]
do
	read -p "Enable ufw [Y/n] " sys_if_use_ufw

	sys_if_use_ufw=$(echo $sys_if_use_ufw | tr 'A-Z' 'a-z')

	if [[ $sys_if_use_ufw != '' && $sys_if_use_ufw != 'y' && $sys_if_use_ufw != 'n' ]]
	then
		echo -e "\033[31m[Error] Selection error.\033[0m"
	fi

	if [[ $sys_if_use_ufw == '' ]]
	then
		sys_if_use_ufw='y'
	fi
done


#-----------------------------
#   check configuration
#-----------------------------
clear

echo "We are going to do: "
echo "  "
echo "  "
echo "  "
echo "  "
echo "  "
echo
echo
echo "If that is OK, press [Enter] to execute to installation"
echo "If not, press [Ctrl - C] to discard the configuration and execute this script file again."
read





#-----------------------------
#   deployment
#-----------------------------

#update list
apt update

#   update system
if [[ $sys_if_update_system == 'y' ]]
then
	update_system
fi

#   config ufw
if [[ $sys_if_use_ufw == 'n' ]]
then
	ufw_shutdown
elif [[ $sys_if_use_ufw == 'y' ]]
then
	ufw_active
	ufw_open_port 22 80 443
fi

#   install nginx
apt install nginx -y
systemctl start nginx
systemctl enable nginx

##   install database
#   MySQL
if [[ $db_type == 'mysql' || $db_type == '1' ]]
then
	apt install mysql-server -y
	db_mysql_init $db_if_unix_socket $db_if_remote_access
	db_mysql_set

#   mariaDB
elif [[ $db_type == 'mariadb' || $db_type == '2' ]]
then
	apt install mariadb-server mariadb-client -y
	db_mariadb_init $db_if_unix_socket $db_if_remote_access
	db_mariadb_set

#   Error
else
	echo -e "\033[31m[Error] Something's wrong. Exiting...\033[0m"
	exit
fi

if [[ $db_if_remote_access == 'y' ]]
then
	ufw_open_port 3306
	if [[ $db_type == 'mysql' || $db_type == '1' ]]
	then
		cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak
		sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
		systemctl restart mysql
		systemctl enable mysql

	elif [[ $db_type == 'mariadb' || $db_type == '2' ]]
	then
		cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak
		sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf
		systemctl restart mariadb
		systemctl enable mariadb
	fi
fi

#   php-fpm
add-apt-repository universe
apt install php-fpm php-mysql -y

cd /etc/nginx/sites-enabled/
unlink default

cd /etc/nginx/sites-available/
cat > auto_deploy.conf << "EOF"
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
