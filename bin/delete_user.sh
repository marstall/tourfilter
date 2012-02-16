action="delete user $2 (from metro $1) and all their data completely"
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
mysql tourfilter_$1 -uchris -pchris -e "delete terms_users from terms_users,users where terms_users.user_id=users.id and (users.name='$2' or users.email_address='$2');" 
mysql tourfilter_$1 -uchris -pchris -e "delete users from users where (users.name='$2' or users.email_address='$2');" 
mysql tourfilter_$1 -uchris -pchris -e "delete recommendees_recommenders from recommendees_recommenders,users where recommendee_id=users.id and (users.name='$2' or users.email_address='$2');" 
mysql tourfilter_$1 -uchris -pchris -e "delete recommendations from recommendations,users where recommendations.user_id=users.id and (users.name='$2' or users.email_address='$2');" 
mysql tourfilter_$1 -uchris -pchris -e "delete comments from comments,users where comments.user_id=users.id and (users.name='$2' or users.email_address='$2');" 
mysql tourfilter_$1 -uchris -pchris -e "delete users from users where (users.name='$2' or users.email_address='$2');" 
rm ~/tourfilter/public/$1/users/$2.html
else
 echo "You said NO. We didn't $action"
fi

