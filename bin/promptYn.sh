while [ -x $do ]
do
        echo -n "$1 (Y/n)?"
        read line
        if [ $line = "Y" ]
        then
         export do="Y"
        fi
        if [ $line = "n" ]
        then
         export do="n"
        fi
done
echo $do>do


