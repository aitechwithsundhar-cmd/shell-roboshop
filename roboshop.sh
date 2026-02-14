#!/bin/bash
# This script launches EC2 instances and creates Route53 DNS records

set -e  # Exit immediately if any command fails

############################################
# VARIABLES (CHANGE ONLY THESE IF NEEDED)
############################################

AMI_ID="ami-0220d79f3f480ecf5"        # Amazon Linux AMI ID
INSTANCE_TYPE="t3.micro"             # EC2 instance type
SG_ID="sg-096be3dc5a8288c12"          # Security Group ID
REGION="us-east-1"                    # AWS Region

HOSTED_ZONE_ID="Z00261213KEKMBRHYD2W"        # Route53 Hosted Zone ID
DOMAIN_NAME="techdaws.online"         # Your domain name

############################################
# LOOP THROUGH SERVICE NAMES
############################################

for instance in "$@"   # Loop through arguments like frontend mongodb redis
do
    echo "======================================"
    echo "Launching EC2 instance for: $instance"
    echo "======================================"

    ############################################
    # CREATE EC2 INSTANCE & CAPTURE INSTANCE ID
    ############################################

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --security-group-ids "$SG_ID" \
        --region "$REGION" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text
    )

    echo "Instance created with ID: $INSTANCE_ID"

    ############################################
    # WAIT UNTIL INSTANCE IS RUNNING
    ############################################

    aws ec2 wait instance-running \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION"

    echo "Instance is now running"

    ############################################
    # GET IP ADDRESS BASED ON INSTANCE TYPE
    ############################################

    if [ "$instance" == "frontend" ]; then
        # Frontend needs Public IP
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
        )
        RECORD_NAME="frontend.$DOMAIN_NAME"
        echo "Public IP for frontend: $IP"
    else
        # Backend services use Private IP
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$REGION" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME="$instance.$DOMAIN_NAME"
        echo "Private IP for $instance: $IP"
    fi

    ############################################
    # CREATE ROUTE53 DNS RECORD
    ############################################

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch "{
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 2,
                    \"ResourceRecords\": [{\"Value\": \"$IP\"}]
                }
            }]
        }"

    echo "DNS record created: $RECORD_NAME -> $IP"
done

echo "======================================"
echo "ALL INSTANCES & DNS RECORDS CREATED ✅"
echo "======================================"
