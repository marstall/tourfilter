mysql $DB_NAME -u$DB_USERNAME -p$DB_PASSWORD -e'alter table terms add constraint unique (text)'

