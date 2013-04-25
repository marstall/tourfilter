a=$(git tag | cut -c2-4 | sort -n | tail -1) #find highest existing tag
let "b=a+1" #increment by 1
b="r$b" #prepend 'r' to it

echo "writing tag $b to $TOURFILTER_HOME/public/production_tag ..."
echo $b>$TOURFILTER_HOME/public/production_tag

create_user_data_file.sh $b

git commit -am "$1"
git tag -a $b -m "tagging release $b"
git push origin master --tags
echo -e "\n$b"