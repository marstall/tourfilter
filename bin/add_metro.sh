if [ -z $1 ]
 then
      echo "Usage:"
      echo "add_metro.sh metro_code [EX: add_metro.sh miami]"
      exit
fi
echo "creating new root directory tourfilter_$1..."
cd ~
mkdir tourfilter_$1
cp -r tourfilter/config tourfilter/app tourfilter/components tourfilter_$1			#copy entire chicago directory to start
mkdir tourfilter_$1/public
cp -r tourfilter/public/dispatch.lsapi tourfilter/public/stylesheets tourfilter/public/javascripts tourfilter/public/images tourfilter/public/favicon.ico tourfilter/public/robots.txt tourfilter_$1/public

mkdir tourfilter_$1/log

cd tourfilter_$1					#go into tourfilter_newmetro
echo "updating config files for $1 ..."
sed "s/boston/$1/" config/database.yml>config/database.yml.tmpl		#update database.yml.tmpl
cp config/database.yml.tmpl config/database.yml
sed "s/tourfilter/tourfilter_$1/" config/vh_conf.xml>config/tmp 		#update vh_conf.xml
mv config/tmp config/vh_conf.xml


while [ -x $do_database ]
do
        echo -n "drop $1 database and reset schema (Y/n)?"
        read line
        if [ $line = "Y" ]
        then
         echo "ok we're doing it"
         do_database="Y"
        fi
        if [ $line = "n" ]
        then
         echo "ok no database"
         do_database="n"
        fi
done


 # Now create the new database and configure it ...
if [ $do_database = "Y" ]
then
echo "creating database tourfilter_$1 ..."
mysql -uroot -e "create database tourfilter_$1;"

echo "granting privileges to chris@tourfilter_$1 ..."
# give chris user privileges
mysql -uroot -e "grant all on tourfilter_$1.* to 'chris'@'localhost' identified by 'chris'";

echo "dumping existing data from tourfilter_$1 into ./tourfilter_$1.dump.sql ..."
# for safety's sake, immediately make a dump of the database (in case this is run on live data - the next statement is destructive
mysqldump -d tourfilter_$1 -uchris -pchris>tourfilter_$1.dump.sql

# copy the schema from tourfilter_boston into the new database
echo "copying tourfilter_boston schema into tourfilter_$1..."
mysqldump -d tourfilter_boston -uchris -pchris | mysql -uchris -pchris tourfilter_$1

echo "copying shared-table data (metros, tracks) from tourfilter_boston to tourfilter_$1 ... "
# copy the WFMU tables and the metros table into the new database
mysqldump tourfilter_boston -uchris -pchris tracks metros | mysql -uchris -pchris tourfilter_$1

echo "adding $1 to metros tables in all other metros"
query_all_metros.sh "insert into metros (name,code,num_places,status) values ('$1(TEST)','$1',0,'inactive')"

echo "adding $1 to metros table in tourfilter_$1"
mysql -uchris -pchris tourfilter_$1 -e "insert into metros(name,code,num_places,status) values ('$1(TEST)','$1',0,'inactive')"
fi

echo "creating chris and lucy admin rows in tourfilter_$1.users"
mysql -uchris -pchris tourfilter_$1 -e 'insert into users(name,password,email_address,registered_on,privs) values("chris","naimi","chris@tourfilter.com",now(),"admin")'
mysql -uchris -pchris tourfilter_$1 -e 'insert into users(name,password,email_address,registered_on,privs) values("lucy","barbieri","lucylindsey@gmail.com",now(),"admin")'

#echo "restarting webserver ..."
#su -c "lswsctrl restart"

#echo "adding daemon entries for $1 ..."
#regenerate_crontab.sh
#crontab -e

echo "DONE! New metro $1 is almost complete."
echo "Don't forget to:"
echo " - add a VirtualHost and VHostMap section to /opt/lsws/conf/httpd_config.xml"
echo " - update crontab (crontab -e)"
echo " - restart webserver (http://www.tourfilter.com:3030)"



 
