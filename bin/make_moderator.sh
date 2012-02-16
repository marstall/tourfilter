action="make user $1 a moderator in ALL metros?"
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
 query_all_metros.sh "update users set privs='manage_matches' where email_address='$1'"
cat ~/tourfilter/bin/moderator_approval_mail.txt | mail -s "You've been approved as a Tourfilter moderator ($1)"  $1 
cat ~/tourfilter/bin/moderator_approval_mail.txt | mail -s "$1 approved as a Tourfilter moderator "  chris@psychoastronomy.org 
else
 echo "You said NO. We didn't $action"
fi

