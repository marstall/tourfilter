cd $TOURFILTER_HOME
a=$(commit_and_tag.sh "$1" | tail -1)
echo "+++++++++++++++++++++++++++++++++++++++"
echo $a
echo "+++++++++++++++++++++++++++++++++++++++"
deploy.sh $a