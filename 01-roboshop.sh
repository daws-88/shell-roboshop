#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-00234e667183faf3a"  # replace your SG ID
ZONE_ID="Z04973572PK8132GW7876"
DOMAIN_NAME="daws88s.fun"

for instance in $@
do
   INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Test}]" --query 'Instances[0].InstanceId' --output text)
   # get private IP
   if [ $instance != "frontend"]; then
       IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
       RECORD_NAME="$instance.$DOMAIN_NAME"
   else
       IP=$(aws ec2 describe-instances --instance-ids i-0682bd1dbd92ce16c --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
       RECORD_NAME="$DOMAIN_NAME"
   fi

   echo "$instance: $IP"
done   


      
