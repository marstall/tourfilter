for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
	cp ~/tourfilter/public/dispatch.lsapi ~/tourfilter_$name/public 
fi
done
