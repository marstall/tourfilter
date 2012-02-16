date 
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros where code<>'all' order by code asc")
do
 if [ $name != "code" ]; then 
	cd ~/tourfilter/daemon
	echo `date` $name :
	echo `date` sending email ...                
        ruby daemon.rb $name send_email>>~/tourfilter/log/daemon-$name-`date +%Y-%m-%d`.log
        echo `date` expiring caches  ...                
        ruby daemon.rb $name expire_caches>>~/tourfilter/log/daemon-$name-`date +%Y-%m-%d`.log
fi
done
date
