mysql -uchris -pchris tourfilter_shared -e "delete from tourfilter_shared.terms"
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
 	mysql -uchris -pchris tourfilter_$name -e "insert into tourfilter_shared.terms (text,metro_code,mp3_url) select text,'$name',url from tracks,terms where terms.num_mp3_tracks>0 and tracks.term_id=terms.id group by terms.id;" 
 fi
done
