for id in $(mysql tourfilter_$1 -uchris -pchris -e "select distinct matches1.id from  terms,matches matches1,matches matches2 where terms.id=matches1.term_id and matches1.term_id=matches2.term_id and matches1.id<>matches2.id and matches1.status='notified' and matches1.time_status='future' and matches2.time_status='future' and matches2.status='notified' and matches1.date_for_sorting=matches2.date_for_sorting group by terms.text,matches1.date_for_sorting order by terms.text;")
do
 if [ $id != "id" ]; then 
        echo $id :
        mysql -uchris -pchris tourfilter_$1 -e "delete from matches where id=$id" 
 fi
done
