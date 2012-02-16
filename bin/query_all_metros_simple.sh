for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
 	mysql -uchris -pchris --skip-column-names tourfilter_$name -e "$1" 
 fi
done
