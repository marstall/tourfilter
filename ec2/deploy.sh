echo "DEPLOY TOURFILTER"
echo "ex: deploy.sh r1"
echo "Pressing enter will do a full deploy, which consists of the following:"
echo "1. tag HEAD as $1"
echo "2. write out tag name '$1' to $TOURFILTER_HOME/public/production_tag"
echo "3. run <bundle> locally"
echo "4. run <git commit -am>, <git push origin master --tags> locally"
echo "5. remotely perform <git pull;git checkout $1> on all instances of autoscaling group asg_tourfilter_web and asg_tourfilter_daemon"
echo "6. run <bundle pack> on all remote instances"
echo "7. install crontab.web on asg_tourfilter_web instances."
echo "8. restart all group apaches"
echo "9. install crontab.daemon on asg_tourfilter_daemon instances."
echo ""
echo "press <enter> to continue."
read line


echo "writing tag $1 to $TOURFILTER_HOME/public/production_tag ..."
echo $1>$TOURFILTER_HOME/public/production_tag

create_user_data_file.sh $1

echo "committing and pushing new production_tag file and git tag $1"
git commit -am "new production tag: $1"
git tag -a $1 -m 'tagging release $1'
git push origin master --tags

$TOURFILTER_HOME/ec2/deploy_web.sh $1
web_failures=$? # return value
$TOURFILTER_HOME/ec2/deploy_daemon.sh $1
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


