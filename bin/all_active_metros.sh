for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros where status='active'")
do
 if [ $name != "code" ]; then 
	echo $name 
fi
done
