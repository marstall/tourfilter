# loops through running instances
echo ""
echo "DEPLOY TOURFILTER"
echo "ex: deploy.sh r1 1"
echo "Pressing enter will do a full deploy, which consists of the following:"
echo "1. tag HEAD as $1"
echo "2. write out tag name '$1' to $TOURFILTER_HOME/public/production_tag"
echo "3. run <bundle> locally"
echo "4. run <git commit -am>, <git push origin master --tags> locally"
echo "5. remotely perform <git pull;git checkout $1> on all instances of autoscaling group asg_tourfilter_$2"
echo "6. run <bundle pack> on all remote instances"
echo "7. restart all group apaches"
echo ""
echo "press <enter> to continue."
read line

# $1 = current autoscaling-group index (1,2,3, etc.)

echo "writing tag $1 to $TOURFILTER_HOME/public/production_tag ..."
echo $1>$TOURFILTER_HOME/public/production_tag

create_user_data_file.sh $1

echo "committing and pushing new production_tag file and git tag $1"
git commit -am "new production tag: $1"
git tag -a $1 -m 'tagging release $1'
git push origin master --tags

i=0
success=0
fail=0
for instance_id in $(as-describe-auto-scaling-groups asg_tourfilter_$2 | grep INSTANCE | cut -d " " -f 3)
do
	ip_address=`ec2-describe-instances $instance_id | grep INSTANCE | cut -f17`
	let i+=1
	echo "$i: deploying to $ip_address ($instance_id) ..."
	ssh -t ec2-user@$ip_address "source ~/.bash_profile;cd /tourfilter;git pull;git checkout $1;bundle pack;sudo apachectl restart;rm public/index.html"
	echo "checking remote production_tag"
	remote_tag=`curl http://$ip_address/production_tag`
	if [ "$remote_tag" = "$1" ]; then
		echo "success: remote tag on $ip_address was $remote_tag"
		let success+=1
	else
		echo "FAIL"
		let fail+=1
	fi
done

echo ""
echo "---------------------------------------------"
echo ""
echo "successful deploys: $success"
echo "failed deploys: $fail"



