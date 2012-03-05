echo "This will create the asg_tourfilter_$2 scaling group with $3 instances based on AMI $1, with tag $4 deployed on install."
echo "press <enter> to continue."
read line

#create_user_data_file.sh $4
as-create-launch-config lc_tourfilter_$2 --image-id $1 --instance-type m1.small --key kp_tourfilter --group quick-start-1 --user-data=$4
as-create-auto-scaling-group asg_tourfilter_$2 --launch-configuration lc_tourfilter_$2 --availability-zones us-east-1a --min-size $3 --max-size $3 --desired-capacity $3 --load-balancers tourfilter-lb
as-put-notification-configuration asg_tourfilter_$2 --topic-arn arn:aws:sns:us-east-1:122872249816:tourfilter-topic --notification-types autoscaling:EC2_INSTANCE_LAUNCH, autoscaling:EC2_INSTANCE_LAUNCH_ERROR, autoscaling:EC2_INSTANCE_TERMINATE, autoscaling:EC2_INSTANCE_TERMINATE_ERROR
as-describe-notification-configurations --auto-scaling-groups asg_tourfilter_$2
as-describe-auto-scaling-groups asg_tourfilter_$2

