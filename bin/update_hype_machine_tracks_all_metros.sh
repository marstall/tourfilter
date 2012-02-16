cd /home/chris/tourfilter/daemon
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
	ruby update_hype_machine_data.rb $name
fi
done
