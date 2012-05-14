for name in $(mysql tourfilter_shared -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
 	mysqldump -uchris -pchris --databases tourfilter_$name | rds
 fi
done
mysqldump -uchris -pchris --databases tourfilter_shared | rds
