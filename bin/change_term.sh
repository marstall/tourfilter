action="change term '$1' to '$2' across all databases"
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
 query_all_metros.sh "update terms set text='$2' where text='$1'"
else
 echo "You said NO. We didn't $action"
fi

