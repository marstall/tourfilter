echo "This will create the two scaling groups, one for web and one for daemon:"
echo "1. asg_tourfilter_web scaling group with $3 instances based on AMI $1, with tag $2 deployed on install."
echo "2. asg_tourfilter_daemon scaling group with 1 instance based on AMI $1, with tag $2 deployed on install."
echo "press <enter> to continue."
read line

create_web_group.sh $1 $2 $3
create_daemon_group.sh $1 $3 $3


