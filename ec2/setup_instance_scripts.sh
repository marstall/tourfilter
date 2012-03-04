# $1 = current autoscaling-group index (1,2,3, etc.)
i=1
for instance_id in $(as-describe-auto-scaling-groups asg_tourfilter_$1 | grep INSTANCE | cut -d " " -f 3)
do
	ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
	if [ $i = 1 ]; then
		echo "ssh -t ec2-user@$ip_address \$1">~/tourfilter/ec2/ec
		echo "ec: $ip_address"
		chmod a+x ~/tourfilter/ec2/ec
	fi
	echo "ssh -t ec2-user@$ip_address \$1">~/tourfilter/ec2/instance_connect_$i.sh
	chmod a+x ~/tourfilter/ec2/instance_connect_$i.sh
	echo "$i: $ip_address ($instance_id)"
	let i+=1
done


