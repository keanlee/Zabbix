#!/bin/bash 
#author by lihao

# ansi colors for formatting heredoc
ESC=$(printf "\e")
GREEN="$ESC[0;32m"
NO_COLOR="$ESC[0;0m"
RED="$ESC[0;31m"

#--------config yum repo on this server----------
rm -rf /etc/yum.repos.d/*
cp ./repo/*  /etc/yum.repos.d/
echo -e "\e[1;32m setup zabbix repos successfull \e[0m"

#-----------install dependence for install bugzilla-----------------------------------
#DO NOT INSTALL the package perl-homedir, because this would break the Bugzilla installation.
#('perl-homedir' would install perl modules in user folders which won't be accessible by Bugzilla so absolutely do not install it!)

yum install httpd httpd-devel mod_ssl mod_ssl mod_perl mod_perl-devel  -y 1>/dev/null 2>&1
yum install mariadb-server mariadb mariadb-devel php-mysql  -y 1>/dev/null 2>&1
yum install gcc gcc-c++ graphviz graphviz-devel patchutils gd gd-devel wget perl* -x perl-homedir -y 1>/dev/null 2>&1
echo "all dependence of bugzilla has bee installed "

#---------------configuer the firewall -
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

#--------setup mariadb ----------------------------
sed -i '11 i # Bugzilla ' /etc/my.cnf
sed -i '12 i # maximum allowed size of an attachment upload ' /etc/my.cnf
sed -i '13 i #change this if you need more! ' /etc/my.cnf
sed -i '14 i max_allowed_packet=4M ' /etc/my.cnf 
systemctl enable mariadb.service
systemctl start mariadb.service

mysqladmin -uroot password admin &&
mysql -uroot -padmin -e "create database bugs character set utf8;grant all privileges on bugs.* to bugs@localhost identified by 'bugzilla';flush privileges;"
echo "The database is bugs and password is bugzilla"

#-----------install bugzilla---------------
tar -xf ./source/bugzilla-5.0.tar.gz
mv bugzilla-5.0/ /var/www/html/bugzilla/

#---------perl /var/www/html/bugzilla/checksetup.pl
cd /var/www/html/bugzilla
perl checksetup.pl   1>/dev/null 
perl install-module.pl --all   1>/dev/null
perl checksetup.pl 1>/dev/null   2>&1
#-------change the ./localconfig
rm -f ./localconfig

cd $(cd `dirname $0`; pwd)
cp ./conf/localconfig  /var/www/html/bugzilla/

#setup admin user and password 
cd /var/www/html/bugzilla
perl checksetup.pl


#At this point we are nearly done. Execute the following line to comment out a line in the .htaccess file that the Bugzilla installation script created:
sed -i 's/^Options -Indexes$/#Options -Indexes/g' ./.htaccess

#-------Configure Apache to host our Bugzilla installation-----------
cd $(cd `dirname $0`; pwd)
cp ./conf/bugzilla.conf /etc/httpd/conf.d
systemctl start httpd.service
systemctl enable httpd.service

#----------------done ----------------------
echo "Voila! You have now a working Bugzilla 5.0 installation on $(cat /etc/redhat-release). You can now continue to setup the details of Bugzilla within the Bugzilla web interface."
echo "Use a browser and open http://ip-of-your-server/ (replace ip-of-your-server with the ip address of your server). You should now see the Bugzilla page "