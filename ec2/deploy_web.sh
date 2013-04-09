echo "deploying to web autoscaling group <$2> ..."
i=0
web_successes=0
web_failures=0
for instance_id in $(as-describe-auto-scaling-groups $2 | grep INSTANCE | cut -d " " -f 3)
do
	ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
	let i+=1
	echo "$i: deploying to $ip_address ($instance_id) ..."
	ssh -t ec2-user@$ip_address "source ~/.bash_profile;cd /tourfilter;git pull;git checkout $1;sudo bundle pack;crontab config/crontab.web;sudo apachectl restart;rm public/index.html"
	echo "checking remote production_tag"
	remote_tag=`curl http://$ip_address/production_tag`
	if [ "$remote_tag" = "$1" ]; then
		echo "success: remote tag on $ip_address was $remote_tag"
		let web_successes+=1
	else
		echo "FAIL"
		let web_failures+=1
	fi
done

echo ""
echo "---------------------------------------------"
echo ""
echo "successful web deploys: $web_successes"
echo "failed web deploys: $web_failures"
echo ""

exit "$web_failures"


