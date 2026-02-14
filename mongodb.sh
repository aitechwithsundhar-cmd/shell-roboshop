#!/bin/bash

LOG=/tmp/mongodb.log
rm -f $LOG

STATUS_CHECK() {
  if [ $? -eq 0 ]; then
    echo -e "\e[32mSUCCESS\e[0m"
  else
    echo -e "\e[31mFAILURE\e[0m"
    echo "Check log file: $LOG"
    exit 1
  fi
}

echo -n "Disabling MongoDB default module .... "
dnf module disable mongodb -y &>>$LOG
STATUS_CHECK

echo -n "Copying MongoDB 7.0 Repo .... "
cat <<EOF >/etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
STATUS_CHECK

echo -n "Installing MongoDB Server .... "
dnf install mongodb-org -y &>>$LOG
STATUS_CHECK

echo -n "Enabling MongoDB Service .... "
systemctl enable mongod &>>$LOG
STATUS_CHECK

echo -n "Starting MongoDB Service .... "
systemctl start mongod &>>$LOG
STATUS_CHECK

echo -n "Updating MongoDB Bind IP .... "
sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>>$LOG
STATUS_CHECK

echo -n "Restarting MongoDB Service .... "
systemctl restart mongod &>>$LOG
STATUS_CHECK

echo -e "\n🎉 MongoDB 7.0 Installation Completed Successfully 🎉"
