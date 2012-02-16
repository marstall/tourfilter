action="change property $1 to $2 in ALL vh.conf files?"
promptYn.sh "$action"
do=`cat do`
if [ $do = "Y" ] 
then
 echo "OK You said yes, we're going to $action"
 # your code here
cd ~
sed  -r -e "s/<$1>[^<]*<\/$1>/<$1>$2<\/$1>/" */config/vh_conf.xml -ibak

else
 echo "You said NO. We didn't $action"
fi
echo "tourfilter_chicago/config/vh_conf.xml:"
cat tourfilter_chicago/config/vh_conf.xml
