echo "deploying to daemon ..."
i=0
daemon_success=0
instance_id=`as-describe-auto-scaling-groups asg_tourfilter_daemon | grep INSTANCE | cut -d " " -f 3`
ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
echo "$i: deploying to daemon at $ip_address ($instance_id) ..."
ssh -t ec2-user@$ip_address "source ~/.bash_profile;cd /tourfilter;git pull;git checkout $1;bundle pack;sudo apachectl restart;crontab config/crontab.daemon;echo 'daemon $1'>public/index.html"
echo "checking remote production_tag"
remote_tag=`curl http://$ip_address/production_tag`
if [ "$remote_tag" = "$1" ]; then
	echo "success: remote tag on $ip_address was $remote_tag"
	let daemon_success=1
else
	echo "FAIL"
fi




