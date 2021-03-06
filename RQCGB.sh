﻿#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear;
cd /root
rm -f /root/RQCGB.sh
echo -e "\033[33m=========================================================================\033[0m"
echo -e "\033[36m             VPN MYSQL and pam_mysql Automatic installation\033[0m"
echo ""
echo -e "\033[32m                      版本：常规方式 -- 本地数据库\033[0m"
echo ""
echo -e "\033[32m                                                            by 落魄书生\033[0m"
echo -e "\033[35m    请按回车继续开始安装\033[0m"
echo -e "\033[33m==========================================================================\033[0m"
echo "$CopyrightLogo";
read
cd /

yum -y install vixie-cron  
yum -y install crontabs  
yum -y install  openssl openssl-devel  cyrus-sasl cyrus-sasl-devel

cd /etc/openvpn/
rm -f server.conf
wget https://github.com/mu228/LPSS/raw/master/cg/server.conf
wget https://github.com/mu228/LPSS/raw/master/openvpn-auth-pam.so
wget https://github.com/mu228/LPSS/raw/master/bd/connect.sh
wget https://github.com/mu228/LPSS/raw/master/bd/disconnect.sh
wget https://github.com/mu228/LPSS/raw/master/bd/test.sh
chmod +x /etc/openvpn/connect.sh
chmod +x /etc/openvpn/disconnect.sh
chmod +x /etc/openvpn/test.sh

chkconfig crond on
/sbin/service crond restart
cd /etc
wget https://github.com/mu228/LPSS/raw/master/K.sh
chmod 0755 K.sh
sleep 1
echo "40 3 * * * root /etc/openvpn/test.sh"  >> crontab
/sbin/service crond restart
./K.sh &
crontab
echo "crontab..."
rm -f /etc/K.sh

echo "安装mysql..."
yum -y install mysql-server
echo 
sleep 2
echo "启动Mysql服务"
service mysqld start
echo "设置Mysql开机启动"
chkconfig mysqld on
echo "正在开启3306端口"
/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
/etc/rc.d/init.d/iptables save
echo 

sleep 1
echo "pam_mysql安装开始"
yum install -y mysql-devel pam-devel gcc gcc-c++ openssl
sleep 1
echo "pam_mysql下载解压"
wget https://github.com/mu228/LPSS/raw/master/pam_mysql-0.7RC1.tar.gz
tar zxvf pam_mysql-0.7RC1.tar.gz
echo   
sleep 1
cd pam_mysql-0.7RC1
echo "文件校验"
sleep 1
./configure –with-openssl
echo
sleep 2
./configure
echo  
sleep 3
echo  "安装中"
make
make install
ln /lib/security/pam_mysql.* /lib64/security/

cd /etc/pam.d
wget https://github.com/mu228/LPSS/raw/master/bd/openvpn
cd /home
wget https://github.com/mu228/LPSS/raw/master/vpn.sql
echo "安装 完毕"

echo  "重启服务"
service mysqld restart
/etc/init.d/saslauthd start

echo  "设置mysql密码"
mysql -e " 

use mysql;
update user set password=password('vpnadmin') where user='root';
flush privileges;
grant all privileges on *.* to 'root'@'%' identified by '123456' with grant option;

"
service mysqld restart

/etc/init.d/mysqld stop
sleep 1
echo -e "\r" | mysqld_safe --user=mysql --skip-grant-tables --skip-networking & 
sleep 1

mysql -uroot mysql -e "
UPDATE user SET Password=PASSWORD('vpnmysql') where USER='root';

FLUSH PRIVILEGES;

"
/etc/init.d/mysqld restart 

mysql -uroot -pvpnmysql -e "

CREATE DATABASE openvpn;

USE openvpn;

GRANT ALL ON openvpn.* TO 'openvpn'@'localhost' IDENTIFIED BY 'openvpn';

source /home/vpn.sql

INSERT INTO test(username,password,name,note,mo,quota,now,zq,zxzt,start,active,updata,downdata) VALUES('test', ENCRYPT('123456'),'test','12321',1,10240000,0,30,0,0,1,0,0);

"

rm -f /home/vpn.sql

cp /etc/openvpn/easy-rsa/keys/ca.crt /home/

/etc/init.d/saslauthd restart
/etc/init.d/openvpn restart	
service mysqld restart
echo "数据库结构与认证模块测试.."
testsaslauthd -u test -p 123456 -s openvpn

echo '=========================================================================='
echo 
Client='                      本地数据库版安装完毕

         配置模板地址：https://github.com/mu228/LPSS/raw/master/cg/openvpn.ovpn
	  
	  mysql用户名:root  mysql密码：vpnmysql  端口：3306  数据库：openvpn

	        注：证书在home目录 【安全起见 请自行修改数据库信息】
				
==========================================================================';
echo "$Client";


