#!/bin/bash

# Exit if any command fails
set -e

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-096be3dc5a8288c12"
REGION="us-east-1"

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: sh roboshop.sh frontend mongodb redis"
    exit 1
fi

for instance in "$@"
do
    echo "======================================"
    echo "Launching instance: $instance"

    # Create EC2 instance and capture Instance ID
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --region "$REGION" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text
    )

    echo "Instance ID: $INSTANCE_ID"

    # Wait until instance is running
    echo "Waiting for instance to be running..."
    aws ec2 wait instance-running \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION"

    # Fetch IP based on service type
    if [ "$instance" == "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
        )
        echo "Public IP of $instance: $IP"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
        )
        echo "Private IP of $instance: $IP"
    fi

done

echo "======================================"
echo "All instances created successfully 🚀"