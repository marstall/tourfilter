# loops through running instances
echo "deploy latest from repo to autoscaling group asg_tourfilter_$1?"
echo "press <enter> to continue."
read line

# $1 = current autoscaling-group index (1,2,3, etc.)
i=0
for instance_id in $(as-describe-auto-scaling-groups asg_tourfilter_$1 | grep INSTANCE | cut -d " " -f 3)
do
	ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
	let i+=1
	echo "$i: deploying to $ip_address ($instance_id) ..."
	commands_to_execute= 
	ssh -t ec2-user@$ip_address "cd /tourfilter;git pull;sudo apachectl restart"
	echo
done
echo "attempted to deploy to $i instances"


