i=1
for ip_address in $(ec2-describe-instances --filter instance-state-name=running | grep INSTANCE | cut -f 17)
do
	if [ $i = 1 ]; then
		echo "ssh ec2-user@$ip_address \$1">~/tourfilter/ec2/ec
		echo "ec: $ip_address"
	fi

	echo "ssh ec2-user@$ip_address \$1">~/tourfilter/ec2/instance_connect_$i.sh
	chmod a+x ~/tourfilter/ec2/instance_connect_$i.sh
	echo "$i: $ip_address"
	let i+=1
done
chmod a+x ~/tourfilter/ec2/ec


