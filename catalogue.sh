#!/bin/bash

USERID=$(id -u)

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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling NodeJS default version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS"

useradd --system --home /app --shell /sbin/nologin roboshop &>>$LOGS_FILE || true
VALIDATE $? "Creating roboshop user"

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading catalogue code"

cd /app
unzip -o /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Extracting catalogue code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS dependencies"
