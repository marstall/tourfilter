echo "DEPLOY TOURFILTER"
echo "ex: deploy.sh r1 asg_tourfilter_web"
echo "arguments:"
echo "$1 = tag to deploy"
echo "$2 = autoscaling group to deploy to"
echo "Pressing enter will do a full deploy, which consists of the following:"
echo "1. tag HEAD as $1"
echo "2. write out tag name '$1' to $TOURFILTER_HOME/public/production_tag"
echo "3. run <bundle> locally"
echo "4. run <git commit -am>, <git push origin master --tags> locally"
echo "5. remotely perform <git pull;git checkout $1> on all instances of autoscaling group asg_tourfilter_web and asg_tourfilter_daemon"
echo "6. run <bundle pack> on all remote instances"
echo "7. install crontab.web on $2 instances."
echo "8. restart all group apaches"
echo "9. install crontab.daemon on asg_tourfilter_daemon instances."
echo ""
echo "press <enter> to continue."
read line




echo "committing and pushing new production_tag file and git tag $1"
commit_and_tag.sh $1 "new production tag: $1"

$TOURFILTER_HOME/ec2/deploy_web.sh $1 $2
web_failures=$? # return value
#$TOURFILTER_HOME/ec2/deploy_daemon.sh $1
daemon_success=$? #return value

if [ "$web_failures" = "0" ]; then
	echo "web deploy OK"
else
	echo "!!! web failed to deploy to $web_failures instances."
fi

if [ "$daemon_success" = "1" ]; then
	echo "daemon deploy OK"
else
	echo "!!! daemon failed to deploy."
fi


