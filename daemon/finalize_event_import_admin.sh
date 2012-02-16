mysql -uchris -pchris tourfilter_shared -e"update artist_terms set status='valid' where status='new' and match_probability='likely'"
mysql -uchris -pchris tourfilter_shared -e"update artist_terms set status='invalid' where status='new' and match_probability='unlikely'"
