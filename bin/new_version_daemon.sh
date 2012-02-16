date
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros where code<>'all' order by code asc")
do
 if [ $name != "code" ]; then
        cd ~/new_version/daemon
        echo `date` $name :
        echo `date` updating num_trackers  ...                
        ruby daemon.rb $name update_num_trackers 
        echo `date` precaching  ...                
        ruby daemon.rb $name precache 
fi
done
date

