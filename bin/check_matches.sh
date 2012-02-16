query_all_metros.sh "select (select max(id) from matches)-(select count(*) from matches);"

