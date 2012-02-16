for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
mysqldump tourfilter_$name metros -uroot>metros_$name.sql
mysqldump tourfilter_shared metros -uroot | mysql -uroot tourfilter_$name
fi
done
