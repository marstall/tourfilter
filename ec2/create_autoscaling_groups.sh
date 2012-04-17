echo "This will create the two scaling groups, one for web and one for daemon:"
echo "1. asg_tourfilter_web scaling group with $3 instances based on AMI $1, with tag $2 deployed on install."
echo "2. asg_tourfilter_daemon scaling group with 1 instance based on AMI $1, with tag $2 deployed on install."
echo "press <enter> to continue."
read line

#create web group
as-create-launch-config lc_tourfilter_web --image-id $1 --instance-type t1.micro --key kp_tourfilter --group quick-start-1 --user-data=$2
as-create-auto-scaling-group asg_tourfilter_web --launch-configuration lc_tourfilter_web --availability-zones us-east-1a --min-size $3 --max-size $3 --desired-capacity $3 --load-balancers tourfilter-lb
as-put-notification-configuration asg_tourfilter_web --topic-arn arn:aws:sns:us-east-1:122872249816:tourfilter-topic --notification-types autoscaling:EC2_INSTANCE_LAUNCH, autoscaling:EC2_INSTANCE_LAUNCH_ERROR, autoscaling:EC2_INSTANCE_TERMINATE, autoscaling:EC2_INSTANCE_TERMINATE_ERROR
as-describe-notification-configurations --auto-scaling-groups asg_tourfilter_web
as-describe-auto-scaling-groups asg_tourfilter_web

#create daemon instance
as-create-launch-config lc_tourfilter_daemon --image-id $1 --instance-type t1.micro --key kp_tourfilter --group quick-start-1 --user-data=$2
as-create-auto-scaling-group asg_tourfilter_daemon --launch-configuration lc_tourfilter_daemon --availability-zones us-east-1a --min-size 1 --max-size 1 --desired-capacity 1
as-put-notification-configuration asg_tourfilter_daemon --topic-arn arn:aws:sns:us-east-1:122872249816:tourfilter-topic --notification-types autoscaling:EC2_INSTANCE_LAUNCH, autoscaling:EC2_INSTANCE_LAUNCH_ERROR, autoscaling:EC2_INSTANCE_TERMINATE, autoscaling:EC2_INSTANCE_TERMINATE_ERROR
as-describe-notification-configurations --auto-scaling-groups asg_tourfilter_daemon
as-describe-auto-scaling-groups asg_tourfilter_daemon
