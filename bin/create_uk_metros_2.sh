
for name in $(mysql tourfilter_shared -uchris -pchris -e "select code from metros where country_code='uk' order by code asc")
do
 if [ $name != "london" ]; then 
	echo $name :
 echo "creating database tourfilter_$name ..."
mysql -uroot -e "create database tourfilter_$name;"

echo "granting privileges to chris@tourfilter_$name ..."
# give chris user privileges
mysql -uroot -e "grant all on tourfilter_$name.* to 'chris'@'localhost' identified by 'chris'";

echo "dumping existing data from tourfilter_$name into ./tourfilter_$name.dump.sql ..."
# for safety's sake, immediately make a dump of the database (in case this is run on live data - the next statement is destructive
mysqldump tourfilter_$name -uchris -pchris>tourfilter_$name.dump.sql

# copy the schema from tourfilter_boston into the new database
echo "copying tourfilter_boston schema into tourfilter_$name..."
mysqldump -d tourfilter_boston -uchris -pchris | mysql -uchris -pchris tourfilter_$name

echo "adding $name to metros table in tourfilter_$name"
mysql -uchris -pchris tourfilter_$name -e "insert into metros(name,code,num_places,status) values ('$name','$name',0,'inactive')"

icho "creating chris and lucy admin rows in tourfilter_$name.users"
mysql -uchris -pchris tourfilter_$name -e 'insert into users(name,password,email_address,registered_on,privs) values("chris","naimi","chris@tourfilter.com",now(),"admin")'
mysql -uchris -pchris tourfilter_$name -e 'insert into users(name,password,email_address,registered_on,privs) values("lucy","barbieri","lucylindsey@gmail.com",now(),"admin")'
fi
done
