#!/bin/bash
# Source from : https://www.cloudera.com/documentation/enterprise/latest/topics/install_cm_cdh.html
# Yum update And language setting install
yum -y -q update
yum -y -q reinstall glibc-common

# Yum Repository update update for cdh
wget https://archive.cloudera.com/cm6/6.1.1/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
rpm --import https://archive.cloudera.com/cm6/6.3.0/redhat7/yum/RPM-GPG-KEY-cloudera


# Shutdown firewall
systemctl stop firewalld 
systemctl disable firewalld 

# Install JDK
yum install -y oracle-j2sdk1.8
yum install -y java-1.8.0-openjdk-devel

# Install Cloudera Manager Server
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server

JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera /opt/cloudera/cm-agent/bin/certmanager setup --configure-services
#cf /var/log/cloudera-scm-agent/certmanager.log

# Install mariaDB
yum install -y mariadb-server
systemctl stop mariadb
echo <<EOF>> /etc/my.conf
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
symbolic-links = 0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd

key_buffer = 16M
key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space.
#Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your
#system and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

#In later versions of MariaDB, if you enable the binary log and do not set
#a server_id, MariaDB will not start. The server_id must be unique within
#the replicating group.
server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d
EOF
systemctl enable mariadb
systemctl start mariadb

yum -y install expect
export MYSQL_ROOT_PASSWORD="nowage1234"

SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

# Installing the MySQL JDBC Driver for MariaDB
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz 
tar zxvf mysql-connector-java-5.1.46.tar.gz
sudo mkdir -p /usr/share/java/
cd mysql-connector-java-5.1.46
sudo cp mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar

# User and Database create

# # for Test ####################################################################
# export MYSQL_ROOT_PASSWORD="nowage1234"
# for i in scm amon rman hue hive sentry nav navms oozie; do
#     mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "drop database $i;"
#     mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "drop user $i;"
#     # mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "drop user $i@'%';"
# done
# mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "flush privileges"
# mysql -uroot -p$MYSQL_ROOT_PASSWORD mysql -e "select user,host from user"
# ###############################################################################

for i in scm amon rman hue hive sentry nav navms oozie; do
    echo $i    
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "create user $i;"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "set password for '$i' = password('$MYSQL_ROOT_PASSWORD');"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "set password for '$i'@'%' = password('$MYSQL_ROOT_PASSWORD');"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $i DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL ON $i.* TO $i@'%';"
done
mysql -uroot -p$MYSQL_ROOT_PASSWORD mysql -e "flush privileges;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD mysql -e "select user,host from user"
mysql -uhive -p$MYSQL_ROOT_PASSWORD hive -e "show databases;"


# Set up the Cloudera Manager Database
#export MYSQL_ROOT_PASSWORD="nowage1234"
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm $MYSQL_ROOT_PASSWORD
systemctl start cloudera-scm-server
# tail  /var/log/cloudera-scm-server/cloudera-scm-server.log

# Enable ssh password login
cat /etc/ssh/sshd_config |sed 's/PasswordAuthentication no/PasswordAuthentication yes/' > /tmp/sshd_config
rm -f /etc/ssh/sshd_config
cp /tmp/sshd_config  /etc/ssh/sshd_config
systemctl restart sshd


echo "$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD"|passwd root




















