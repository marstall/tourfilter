mysql -uchris -pchris tourfilter_shared -e "delete from tourfilter_shared.terms"
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
 	mysql -uchris -pchris tourfilter_$name -e " update terms set source='$name'" 
 fi
done
