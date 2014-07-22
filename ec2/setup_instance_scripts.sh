# $1 = current autoscaling-group index (1,2,3, etc.)
i=1
for instance_id in $(as-describe-auto-scaling-groups asg_tourfilter_web | grep INSTANCE | cut -d " " -f 3)
do
	ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
	if [ $i = 1 ]; then
		echo "ssh -t ec2-user@$ip_address \$1">~/tourfilterdotcom/ec2/wec
		echo "wec: $ip_address"
		chmod a+x ~/tourfilterdotcom/ec2/wec
	fi
	echo "ssh -t ec2-user@$ip_address \$1">~/tourfilterdotcom/ec2/instance_connect_$i.sh
	chmod a+x ~/tourfilterdotcom/ec2/instance_connect_$i.sh
	echo "$i: $ip_address ($instance_id)"
	let i+=1
done

instance_id2=`as-describe-auto-scaling-groups asg_tourfilter_daemon | grep INSTANCE | cut -d " " -f 3`
ip_address=`ec2-describe-instances $instance_id2 | grep INSTANCE | cut -f17`
echo "ssh -t ec2-user@$ip_address \$1">~/tourfilterdotcom/ec2/dec
echo "dec: $ip_address"
	chmod a+x ~/tourfilterdotcom/ec2/dec
echo "$i: $ip_address ($instance_id2)"


