echo "creating web group ..."

#create web group
as-create-launch-config lc_tourfilter_web --image-id $1 --instance-type m1.small --key kp_tourfilter --group quick-start-1 --user-data=$2
as-create-auto-scaling-group asg_tourfilter_web --launch-configuration lc_tourfilter_web --availability-zones us-east-1a --min-size $3 --max-size $3 --desired-capacity $3 --load-balancers tourfilter-lb
as-put-notification-configuration asg_tourfilter_web --topic-arn arn:aws:sns:us-east-1:122872249816:tourfilter-topic --notification-types autoscaling:EC2_INSTANCE_LAUNCH, autoscaling:EC2_INSTANCE_LAUNCH_ERROR, autoscaling:EC2_INSTANCE_TERMINATE, autoscaling:EC2_INSTANCE_TERMINATE_ERROR
as-describe-notification-configurations --auto-scaling-groups asg_tourfilter_web
as-describe-auto-scaling-groups asg_tourfilter_web
