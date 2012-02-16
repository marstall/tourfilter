date 
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros where code<>'all' order by code asc")
do
 if [ $name != "code" ]; then 
	cd ~/tourfilter/daemon
	echo `date` $name :
	echo `date` syncing lastfm ...		
	ruby daemon.rb $name lastfm_sync>~/tourfilter/log/daemon-$name-`date +%Y-%m-%d`.log 
fi
done
date
