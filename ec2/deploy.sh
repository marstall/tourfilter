# loops through running instances
echo ""
echo "DEPLOY TOURFILTER"
echo "Pressing enter will do a full deploy, which consists of the following:"
echo "1. tag HEAD as $1"
echo "2. write out tag name '$1' to $TOURFILTER_HOME/public/production_tag"
echo "3. run <git commit -am> and <git push origin master> locally"
echo "4. remotely perfom <git checkout $1> on all instances of autoscaling group asg_tourfilter_$2"
echo "5. restart all apaches in autoscaling group asg_tourfilter_$2"
echo ""
echo "press <enter> to continue."
read line

# $1 = current autoscaling-group index (1,2,3, etc.)

echo "writing tag $1 to $TOURFILTER_HOME/public/production_tag ..."
echo $1>$TOURFILTER_HOME/public/production_tag

echo "creating $TOURFILTER_HOME/ec2/user_data_file.sh ..."
echo "git checkout $1">$TOURFILTER_HOME/ec2/user_data_file.sh

echo "committing and pushing new production_tag file and git tag $1"
git commit -am "new production tag: $1"
git tag -a $1 -m 'tagging release $1'
git push origin master

i=0
for instance_id in $(as-describe-auto-scaling-groups asg_tourfilter_$2 | grep INSTANCE | cut -d " " -f 3)
do
	ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
	let i+=1
	echo "$i: deploying to $ip_address ($instance_id) ..."
	ssh -t ec2-user@$ip_address "cd /tourfilter;git checkout $1;sudo apachectl restart"
	echo
done


echo "deployed to $i instances."


