query_all_metros.sh "select id,uid,date_for_sorting,status,time_status from matches where uid like '%$1%'"
mysql -uchris -pchris tourfilter_shared -e"select * from artist_terms where term_text='$1';"
