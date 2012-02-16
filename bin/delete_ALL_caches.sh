for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
	rm -rf ~/tourfilter/public/$name
	rm -rf ~/tourfilter/cache/www.tourfilter.com/$name
fi
done
rm -rf ~/tourfilter/public/*html*

