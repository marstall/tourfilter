mysql -v -v $DB_NAME -u$DB_USERNAME -p$DB_PASSWORD -e"delete from terms where text='$1' and id<>$2"

