action="delete term '$1' in all databases"
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
 query_all_metros.sh "delete from terms_users where term_id in (select id from terms where text like '$1')"
 query_all_metros.sh "delete from matches where term_id in (select id from terms where text like '$1')"
 query_all_metros.sh "delete from terms where text like '$1'"
else
 echo "You said NO. We didn't $action"
fi

