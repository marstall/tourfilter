

for name in $(mysql tourfilter_all -uchris -pchris -e "select code from metros where status='inactive' order by code asc")
do
 if [ $name != "code" ]; then 
        echo $name :
mysql -uroot -e "create database tourfilter_$name;"

echo "granting privileges to chris@tourfilter_$name ..."
# give chris user privileges
mysql -uroot -e "grant all on tourfilter_$name.* to 'chris'@'localhost' identified by 'chris'";

# copy the schema from tourfilter_boston into the new database
echo "copying tourfilter_boston schema into tourfilter_$name..."
mysqldump -d tourfilter_boston -uchris -pchris | mysql -uchris -pchris tourfilter_$name

echo "creating chris and lucy admin rows in tourfilter_$name.users"
mysql -uchris -pchris tourfilter_$name -e 'insert into users(name,password,email_address,registered_on,privs) values("chris","naimi","chris@tourfilter.com",now(),"admin")'
mysql -uchris -pchris tourfilter_$name -e 'insert into users(name,password,email_address,registered_on,privs) values("lucy","barbieri","lucylindsey@gmail.com",now(),"admin")'
fi
done




 
