cd ~/tourfilter
a=$(commit_and_tag.sh $1 | tail -1)
echo "+++++++++++++++++++++++++++++++++++++++"
echo $a
echo "+++++++++++++++++++++++++++++++++++++++"
deploy_web.sh $a asg_new_tourfilter_web