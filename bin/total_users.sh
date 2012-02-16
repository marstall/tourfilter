echo "hits    sess    ret    signups">ds.tmp
for name in $(mysql tourfilter_boston -uchris -pchris -e "select code from metros")
do
 if [ $name != "code" ]; then 
count=`mysql tourfilter_$name -uchris -pchris --skip-column-names -e'select count(*) from users where (last_visited_on is not null or referer_domain is not null)'`
        total=$((total+count))      
echo $name: $count 
fi
done>>~/ds.tmp
cat ~/ds.tmp | sed -r 's/[ \t$]0//g'>~/ds
rm ~/ds.tmp
cat ~/ds
echo ------------
echo total:      $total


