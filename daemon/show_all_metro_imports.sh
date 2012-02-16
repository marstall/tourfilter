for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
        echo $name :
mysql -uchris -pchris tourfilter_$name -e"select id,uid,date_for_sorting,status,time_status from matches where uid is not null and date_for_sorting>now() and created_at>adddate(now(),interval -1 day) order by uid"
fi
done
