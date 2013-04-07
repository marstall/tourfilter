query_all_metros.sh "delete from matches where uid like '%$1%'"
mysql -uchris -pchris tourfilter_shared -e"update artist_terms set status='invalid' where term_text='$1'"
