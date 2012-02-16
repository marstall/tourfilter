cd /home/chris/tourfilter/daemon
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros where num_places is not null order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
	ruby newsletter_daemon.rb $name
	sleep 180 # wait 3 minutes for mail queue to flush
fi
done
