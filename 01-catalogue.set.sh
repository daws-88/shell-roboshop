#!/bin/bash

set -euo pipefail
trap 'echo "There is an error in $LINE_NO; Command is $BASH_COMAND"' ERR
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
START_TIME=$(date +%s)
MONGODB_HOST=mongodb.daws88s.fun
SCRIPT_DIR=$PWD
USERID=$(id -u)
LOG_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOG_FOLDER
echo "Script strated at $(date)" | tee -a $LOG_FILE
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script as root privelliage"
    exit 1
fi

###### CATALOGUE ####

dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE
echo "Installing Nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    echo "create user"
else
    echo -e "User already exist...$Y SKIPPING $N"| tee -a $LOG_FILE
fi

mkdir -p /app
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
cd /app
rm -rf /app/* $>>$LOG_FILE
unzip /tmp/catalogue.zip &>>LOG_FILE
echo "create app,download code"

npm install &>>$LOG_FILE
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>LOG_FILE
echo "demon-reload enable catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh mongodb.daws88s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "products already exist..$Y SKIPPING $N"
fi
systemctl restart catalogue
echo "catalogue restrated"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in:$Y $TOTAL_TIME in seconds $N"