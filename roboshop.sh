#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-096be3dc5a8288c12"

for instance in "$@"
do
    echo "Launching instance: $instance"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text
    )

    echo "Instance ID: $INSTANCE_ID"

    if [ "$instance" == "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
        )
        echo "Public IP of $instance: $IP"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
        )
        echo "Private IP of $instance: $IP"
    fi

done