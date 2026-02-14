#!/bin/bash 

# 1) check root user or not
# 2) if root user then continue, otherwise given an error 
# 3) adding colors 
# 4) Check logs 
# 5) Validate function

USERID=$(id -u)

LOGS_FOLDER="/var/log/roboshop"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$0.log"

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Root check
if [ $USERID -ne 0 ]; then
    echo -e "${R}Please run this script with root user access${N}" | tee -q $LOGS_FILE
    exit 1
fi

# Create logs folder
mkdir -p "$LOGS_FOLDER"

# Validation function
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 .... ${R}FAILURE${N}" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 .... ${G}SUCCESS${N}" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
# shell-roboshop/mongo.repo
VALIDATE $? "Copying Mongo Repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "installing mongoDB server"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "enable mongoDB"

systemctl start mongod 
VALIDATE $? "start mondoDB"

# we can't edit directly using VIM as robot(automate) so we need to use
# sed editor -> streamline editor 
# insert text after line 1. to delete use 'd' example :- sed '2d' user 
# sed 'la hi ' users -> add the text after line 1, temporary edit only on screen. for premenent usr -i option 
# sed '1i hello'users -> before line 1
# sed '/sbin/d' -> deletes all the lines with text math sbin/d 
# sed '2d' ->delete 2nd line 
# sed '2s/sbin/SBIN/g'users -> replace sbin with SBIN in 2nd line 
# sed 's/sbin/SBIN/g' -> all lines all occurences 

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/momgod.conf
VALIDATE $? "allowing remote connections"

systemctl restart mongod
VALIDATE $? "restarted mongoDB"
