# loops through running instances
echo ""
echo "DEPLOY TOURFILTER"
echo "ex: deploy.sh r1 1"
echo "Pressing enter will do a full deploy, which consists of the following:"
echo "1. tag HEAD as $1"
echo "2. write out tag name '$1' to $TOURFILTER_HOME/public/production_tag"
echo "3. run <bundle> locally"
echo "4. run <git commit -am>, <git push origin master --tags> locally"
echo "5. remotely perfom <git pull;git checkout $1> on all instances of autoscaling group asg_tourfilter_$2"
echo "6. run <bundle> on all remote instances"
echo "7. restart all group apaches"
echo ""
echo "press <enter> to continue."
read line

# $1 = current autoscaling-group index (1,2,3, etc.)

echo "writing tag $1 to $TOURFILTER_HOME/public/production_tag ..."
echo $1>$TOURFILTER_HOME/public/production_tag

echo "creating $TOURFILTER_HOME/ec2/user_data_file.sh ..."
echo -e "#! \ngit checkout $1">$TOURFILTER_HOME/ec2/user_data_file.sh

echo "committing and pushing new production_tag file and git tag $1"
git commit -am "new production tag: $1"
git tag -a $1 -m 'tagging release $1'
git push origin master --tags

i=0
for instance_id in $(as-describe-auto-scaling-groups asg_tourfilter_$2 | grep INSTANCE | cut -d " " -f 3)
do
	ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
	let i+=1
	echo "$i: deploying to $ip_address ($instance_id) ..."
	ssh -t ec2-user@$ip_address "cd /tourfilter;git pull;git checkout $1;bundle;sudo apachectl restart"
	echo
done


echo "deployed to $i instances."


