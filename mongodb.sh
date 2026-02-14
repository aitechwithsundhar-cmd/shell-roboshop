#!/bin/bash

############################################
# MongoDB Installation Script (Automated)
############################################

USERID=$(id -u)

LOGS_FOLDER="/var/log/roboshop"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Root check
if [ $USERID -ne 0 ]; then
    echo -e "${R}Please run this script as root${N}"
    exit 1
fi

# Create logs folder
mkdir -p $LOGS_FOLDER

# Validation function
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 .... ${R}FAILURE${N}" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 .... ${G}SUCCESS${N}" | tee -a $LOGS_FILE
    fi
}

############################################
# Copy Mongo Repo

############################################
cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "Copying Mongo Repo"

############################################
# Install MongoDB
############################################
dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB Server"

############################################
# Enable & Start MongoDB
############################################
systemctl daemon-reload &>>$LOGS_FILE

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Starting MongoDB"

############################################
# Allow Remote Connections (Automation way)
############################################
# Replace bindIp from 127.0.0.1 → 0.0.0.0
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

############################################
# Restart MongoDB
############################################
systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting MongoDB"

echo -e "${G}MongoDB setup completed successfully 🚀${N}"
