for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
        echo $name :
        sed  -r -e "s/<name>[^<]*<\/name>/<name>tourfilter_$name<\/name>/" tourfilter_$name/config/vh_conf.xml -ibak
        sed  -r -e "s/<handler>[^<]*<\/handler>/<handler>tourfilter_$name<\/handler>/" tourfilter_$name/config/vh_conf.xml -ibak
 fi
done

