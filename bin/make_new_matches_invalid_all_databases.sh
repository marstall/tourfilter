action="make all new matches invalid"
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
 mysql -uchris -pchris tourfilter_$1 -e"update matches set status='invalid' where status='new'"
else
 echo "You said NO. We didn't $action"
fi

