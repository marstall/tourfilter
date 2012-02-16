for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
 	mysql -uchris -pchris tourfilter_$name -e "insert ignore into terms (text,source) select text,source from tourfilter_shared.shared_terms;"
 fi
done
