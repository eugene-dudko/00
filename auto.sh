#!/bin/bash
echo -e "\033[1;31m""Script tested for Debian only""\033[0m"
#apt update
#apt install -y apache2 php default-mysql-server php7.3-mysql jq


###apt check & instlall if not exist && print already exists :)
for apt in apache2 php default-mysql-server php7.3-mysql jq
do
echo CHECK----- $apt item
ap=$(apt list --installed | grep "$apt" | awk '{print $1, $4}')
if [ -z "$ap" ]
then
    echo "NEED $apt.....installing $apt"
    apt install "$apt";
else
    echo "already exists...:"
    echo "$ap"
fi
done

a2enmod php*

#read data from json;
db_name=$(cat ./config.json | jq --raw-output '.db.name')
db_user=$(cat ./config.json | jq --raw-output '.db.username')
db_pass=$(cat ./config.json | jq --raw-output '.db.password')
st_name=$(cat ./config.json | jq --raw-output '.sitename')
st_rdir=$(cat ./config.json | jq --raw-output '.siteroot_dir')

###download untar r\move WodrPress
#wget https://uk.wordpress.org/latest-uk.tar.gz
#tar -zxvf latest-uk.tar.gz -C /var/www/html/
#mv /var/www/html/wordpress/* /var/www/html/
#rm /var/www/html/index.html
#rmdir /var/www/html/wordpress/
#rm ./latest-uk.*

###drop\craete db, user
#mysql -e "drop database \`$db_name\` ; drop user '$db_user'@'localhost';"
mysql -e "create database \`$db_name\`; create user '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; grant all on \`$db_name\`.* to '$db_user'@'localhost'; set password for '$db_user'@'localhost' = password('$db_pass');"

###create virtual host

#rmdir $st_rdir/$st_name
#mkdir $st_rdir/$st_name

if ! [ -d $st_rdir/$st_name ];
then
    echo "127.0.0.1 $st_name" >> /etc/hosts
    echo "mkdir $st_rdir"
    mkdir -p $st_rdir/$st_name
    mkdir -p $st_rdir/$st_name/logs
    chown -R 777 $st_rdir/$st_name
###VH:
    echo "<VirtualHost *:80>
    ServerName $st_name
    DocumentRoot $st_rdir
    <Directory $st_rdir>
    AllowOverride All
    </Directory>
    ErrorLog $st_rdir/$st_name/logs/error_log
</VirtualHost>" >> /etc/apache2/sites-available/$st_name
##Apache conf renew & enable $st_name
    s2ensite $st_name
    systemctl reload apache2


    echo "CREATED" $st_rdir/$st_name
else
    echo "DOMAIN ALREADY EXISTS. :" $st_rdir/$st_name
    echo "CHANGE VH NAME" $st_name

fi
#ln -s /etc/apache2/sites-available/$st_name /etc/apache2/sites-enabled/
#ln -s /etc/apache2/sites-available/$st_name /var/www/html

###BACKups once per day
dt=$(date +'%F')
d2=$(date +'%F_%H-%M')
##from json
df="/var/backup"
df2="/etc/apache2"
mkdir -p $df/$dt
dt2="$df/$dt"
#rsync -avtD $st_rdir $dt2
#rsync -avtD $df2 $dt2
per1="0,15,30,45 * * * * "
echo $d2
##restore dump
#re=$(mysqldump -u root  --databases  $db_name < $df/$d2.sql)

#add to cron dump folders
crontab <<EOF
$per1 mysqldump -u root --databases $db_name > $df/$d2.sql
$per1 rsync -avtD $st_rdir $dt2
$per1 rsync -avtD $df2 $dt2

EOF

service cron reload





#####################
#####config.json#####
#{
#  "sitename": "mysite.local",
#  "siteroot_dir": "/var/www/html",
#  "db": {
#    "username": "mysite",
#    "password": "strongpwd",
#    "name": "mydb"
#  }
#}
#####################
