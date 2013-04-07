echo "creating daemon group ..."
#create daemon instance
as-create-launch-config lc_tourfilter_daemon --image-id $1 --instance-type m1.small --key kp_tourfilter --group quick-start-1 --user-data=$2
as-create-auto-scaling-group asg_tourfilter_daemon --launch-configuration lc_tourfilter_daemon --availability-zones us-east-1a --min-size 1 --max-size 1 --desired-capacity 1
as-put-notification-configuration asg_tourfilter_daemon --topic-arn arn:aws:sns:us-east-1:122872249816:tourfilter-topic --notification-types autoscaling:EC2_INSTANCE_LAUNCH, autoscaling:EC2_INSTANCE_LAUNCH_ERROR, autoscaling:EC2_INSTANCE_TERMINATE, autoscaling:EC2_INSTANCE_TERMINATE_ERROR
as-describe-notification-configurations --auto-scaling-groups asg_tourfilter_daemon
as-describe-auto-scaling-groups asg_tourfilter_daemon
