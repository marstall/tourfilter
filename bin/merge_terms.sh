for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
        echo $name :
        mysql -uchris -pchris tourfilter_$name -e "insert ignore into tourfilter_shared.shared_terms (text,url,source) select text,url,source from terms group by terms.text"
 fi
done

