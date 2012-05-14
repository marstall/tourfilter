action="make all new matches invalid in ALL metros"
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
for name in $(m shared "select code from metros")
do
 if [ $name != "code" ]; then
 echo m $name -e"update matches set status='invalid' where status='new'"
 m $name "update matches set status='invalid' where status='new'"
fi
done
echo "done."
else
 echo "You said NO. We didn't $action"
fi

