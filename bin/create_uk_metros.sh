mysql -uroot -p tourfilter_shared -e"alter table metros add column country_code char(2); update metros set country_code='us'"

mysql -uchris -pchris tourfilter_shared -e"INSERT INTO `metros` VALUES (1161,'Bristol','bristol',NULL,'active','uk',NULL,-2.5919023,51.4553129,'uk'),(1160,'Nottingham','nottingham',NULL,'active','uk',NULL,-1.1493098,52.9551076,'uk'),(1159,'Newcastle','newcastle',NULL,'active','uk',NULL,-1.6129165,54.9778404,'uk'),(1158,'Glasgow','glasgow',NULL,'active','uk',NULL,-4.2572227,55.8656274,'uk'),(1157,'Leeds','leeds',NULL,'active','uk',NULL,-1.54911,53.7996374,'uk'),(1156,'Manchester','manchester',NULL,'active','uk',NULL,-2.2343765,53.4807125,'uk'),(1162,'Belfast','belfast',NULL,'active','uk',NULL,-5.9301088,54.5972686,'uk'),(1163,'Cardiff','cardiff',NULL,'active','uk',NULL,-3.1804979,51.4813069,'uk'),(1164,'Southhampton','southhampton',NULL,'active','uk',NULL,-1.403234,50.904966,'uk'),(1165,'Liverpool','liverpool',NULL,'active','uk',NULL,-2.9778383,53.4107766,'uk'),(1166,'Sheffield','sheffield',NULL,'active','uk',NULL,-1.4647953,53.3830548,'uk'),(1167,'Brighton','brighton',NULL,'active','uk',NULL,-0.1365716,50.8197155,'uk'),(1168,'Edinburgh','edinburgh',NULL,'active','uk',NULL,-3.1875359,55.9501755,'uk'),(1169,'Leicester','leicester',NULL,'active','uk',NULL,-1.1294433,52.6345701,'uk'),(1170,'Stoke-On-Trent','stoke_on_trent',NULL,'active','uk',NULL,-2.176636,53.0265029,'uk'),(1171,'Kingston-Upon-Hull','kingston_upon_hull',NULL,'active','uk',NULL,-0.3318277,53.7581538,'uk'),(1172,'Aberdeen','aberdeen',NULL,'active','uk',NULL,-2.0953919,57.1474934,'uk'),(1173,'Portsmouth','portsmouth',NULL,'active','uk',NULL,-1.0911627,50.7989137,'uk');"

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
