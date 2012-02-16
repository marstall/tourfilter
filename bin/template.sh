action=""
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
 # your code here
else
 echo "You said NO. We didn't $action"
fi

