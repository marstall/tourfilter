for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
	time wget http://$name.tourfilter.com &
	time wget http://$name.tourfilter.com/about 
fi
done
