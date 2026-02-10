#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-00234e667183faf3a"  # replace your SG ID
ZONE_ID="Z04973572PK8132GW7876"
DOMAIN_NAME="daws88s.fun"

for instance in $@
do
   INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$instance}]' --query 'Instances[0].InstanceId' --output text)

done


      
