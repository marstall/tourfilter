 query_all_metros.sh "delete from terms_users where term_id in (select id from terms where text='$1');delete from matches where term_id in (select id from terms where text='$1');delete from terms where text='$1'"
 m shared "delete from shared_terms where text='$1';update artist_terms set status='invalid' where term_text='$1';"


