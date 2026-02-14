#!/bin/bash

USERID=$(id -u)

SCRIPT_DIR=$(dirname "$(realpath "$0")")


LOGS_FOLDER="/var/log/roboshop"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

R="\e[31m"
G="\e[32m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
  echo -e "${R}Please run as root${N}"
  exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "$2 ... ${R}FAILURE${N}"
    exit 1
  else
    echo -e "$2 ... ${G}SUCCESS${N}"
  fi
}

cp "$SCRIPT_DIR/mongo.repo" /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongo Repo"

dnf clean all &>>$LOGS_FILE
dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB Server"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
VALIDATE $? "Allow remote access"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restart MongoDB"
