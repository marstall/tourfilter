mysql -v $DB_NAME -u$DB_USERNAME -p$DB_PASSWORD -e"select * from terms where text='$1'"
mysql -v -v $DB_NAME -u$DB_USERNAME -p$DB_PASSWORD -e"update matches set term_id=(select id from terms where text='$1' limit 1) where term_id in (select id from terms where text='$1')"
mysql -v -v $DB_NAME -u$DB_USERNAME -p$DB_PASSWORD -e"update terms_users set term_id=(select id from terms where text='$1' limit 1) where term_id in (select id from terms where text='$1')"
