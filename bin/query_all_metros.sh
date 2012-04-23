for name in $(m shared "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
	echo $name :
 	m $name "$1" 
 fi
done
